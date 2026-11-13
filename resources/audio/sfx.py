#!/usr/bin/env python3
"""Outils audio de Sirene (agent audio al1x) : analyze, process, fetch.

Python 3.9+ (bibliothèque standard seule) + ffmpeg/ffprobe dans le PATH.
Lancer avec `python3 -I sfx.py ...` depuis un dossier qui n'est pas la quarantaine.
"""
import argparse
import datetime
import hashlib
import json
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

# Mesure : "momentary" = loudness momentané max (fenêtre 400 ms, fiable sur les sons courts),
# "integrated" = LUFS intégré (boucles et musique). Cibles par défaut, à remplacer par la
# référence du projet quand elle existe (--target).
CATEGORIES = {
    "arme": ("momentary", -14.0),
    "impact": ("momentary", -14.0),
    "ui": ("momentary", -20.0),
    "ambiance": ("integrated", -26.0),
    "musique": ("integrated", -18.0),
}
TRUE_PEAK_CEILING = -1.0
SAMPLE_RATE = 48000
SILENCE_BELOW_PEAK_DB = 60.0
FADE_IN_S = 0.003
FADE_OUT_MAX_S = 0.05
# Planchers d'ebur128 : un fichier muet y reste (jamais -inf), donc tout niveau à ce plancher = silence.
SILENCE_FLOOR = {"momentary": -120.0, "integrated": -70.0, "true_peak": float("-inf")}

ALLOWED_CONTAINERS = {"wav", "ogg", "mp3", "flac", "aiff"}
AUDIO_EXTENSIONS = {".wav", ".ogg", ".mp3", ".flac", ".aif", ".aiff"}
MAX_INPUT_BYTES = 500 * 1024 * 1024
MAX_DURATION_S = 1800

# Licences acceptées par fetch : niveau 1 = sans crédit, niveau 2 = crédit obligatoire. Tout le reste est refusé.
LICENSES = {
    "cc0": (1, "CC0 1.0"),
    "cc-by-3.0": (2, "CC BY 3.0"),
    "cc-by-4.0": (2, "CC BY 4.0"),
    "oga-by-3.0": (2, "OGA-BY 3.0"),
}
# Packs Kenney : passer par leur miroir OpenGameArt (kenney.nl exige une session pour télécharger).
FETCH_HOSTS = {"opengameart.org", "www.opengameart.org"}
MANUAL_HOSTS = {"pixabay.com", "www.pixabay.com", "cdn.pixabay.com", "kenney.nl", "www.kenney.nl",
                "mixkit.co", "sonniss.com"}
MAX_DOWNLOAD_BYTES = 1024 * 1024 * 1024
MAX_EXTRACTED_BYTES = 2 * 1024 * 1024 * 1024
USER_AGENT = "al1x-sfx-fetch/1.0"


def fail(message):
    print(f"ERREUR : {message}", file=sys.stderr)
    sys.exit(1)


def run(cmd):
    return subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, encoding="utf-8", errors="replace")


def ffmpeg(*args):
    return ["ffmpeg", "-hide_banner", "-nostdin", "-nostats", "-protocol_whitelist", "file", *args]


# ---------- Vérification et mesures ----------

def probe(path):
    """Vérifie qu'un fichier est bien de l'audio exploitable avant tout traitement."""
    path = Path(path)
    if not path.is_file():
        fail(f"fichier introuvable : {path}")
    if path.stat().st_size > MAX_INPUT_BYTES:
        fail(f"fichier trop gros : {path}")
    result = run(["ffprobe", "-v", "error", "-protocol_whitelist", "file", "-of", "json",
                  "-show_entries", "format=format_name,duration:stream=codec_type,codec_name,channels,sample_rate",
                  str(path)])
    if result.returncode != 0:
        fail(f"ffprobe refuse {path.name} : {result.stderr.strip()[:200]}")
    info = json.loads(result.stdout)
    containers = set(info.get("format", {}).get("format_name", "").split(","))
    if not containers & ALLOWED_CONTAINERS:
        fail(f"conteneur non audio ou non pris en charge : {path.name} ({','.join(containers)})")
    audio = [s for s in info.get("streams", []) if s.get("codec_type") == "audio"]
    if not audio:
        fail(f"aucune piste audio : {path.name}")
    declared = float(info["format"].get("duration") or 0)
    if not 0 < declared <= MAX_DURATION_S:
        fail(f"durée invalide ({declared:.2f} s) : {path.name}")
    stream = audio[0]
    sample_rate = int(stream.get("sample_rate", 0))
    return {
        "duration": decoded_duration(path, sample_rate),
        "channels": int(stream.get("channels", 0)),
        "sample_rate": sample_rate,
        "codec": stream.get("codec_name", "?"),
    }


def decoded_duration(path, sample_rate):
    """Durée réellement décodée : celle du conteneur inclut le padding de l'encodeur (MP3)."""
    result = run(ffmpeg("-i", str(path), "-map", "0:a:0",
                        "-af", "astats=measure_perchannel=none:measure_overall=Number_of_samples", "-f", "null", "-"))
    samples = re.findall(r"Number of samples: (\d+)", result.stderr)
    if result.returncode != 0 or not samples or sample_rate <= 0 or int(samples[-1]) == 0:
        fail(f"décodage impossible : {path.name}")
    return int(samples[-1]) / sample_rate


def is_silent(levels, key):
    return levels[key] <= SILENCE_FLOOR[key]


def measure(path):
    """Loudness momentané max, intégré et pic vrai (EBU R128).

    Un son plus court que la fenêtre momentanée (400 ms) est répété pour la remplir :
    sinon un clic de 60 ms paraît 8 dB plus faible qu'il ne l'est et sa cible devient inatteignable.
    """
    loop = ["-stream_loop", "-1", "-t", "1.2"] if probe(path)["duration"] < 0.4 else []
    result = run(ffmpeg("-v", "verbose", *loop, "-i", str(path), "-map", "0:a:0",
                        "-af", "apad=pad_dur=0.4,ebur128=peak=true:framelog=verbose", "-f", "null", "-"))
    if result.returncode != 0:
        fail(f"mesure impossible : {Path(path).name}")
    log = result.stderr
    momentary = [float(v) for v in re.findall(r"\bM:\s*(-?[\d.]+)", log)]
    summary = log[log.rfind("Summary:"):]
    integrated = re.search(r"I:\s*(-?[\d.]+) LUFS", summary)
    peak = re.search(r"True peak:\s*Peak:\s*(-?[\d.]+|-inf)", summary)
    peak_value = float(peak.group(1)) if peak and peak.group(1) != "-inf" else float("-inf")
    return {
        "momentary": max(momentary) if momentary else float("-inf"),
        "integrated": float(integrated.group(1)) if integrated else float("-inf"),
        "true_peak": peak_value,
    }


def silences(path, duration, true_peak):
    """Silence de début et de fin, seuil relatif au pic."""
    threshold = max(true_peak - SILENCE_BELOW_PEAK_DB, -90.0)
    result = run(ffmpeg("-i", str(path), "-map", "0:a:0",
                        "-af", f"silencedetect=n={threshold:.1f}dB:d=0.01", "-f", "null", "-"))
    starts = [float(v) for v in re.findall(r"silence_start: (-?[\d.]+)", result.stderr)]
    ends = [float(v) for v in re.findall(r"silence_end: (-?[\d.]+)", result.stderr)]
    ends += [duration] * (len(starts) - len(ends))
    lead = ends[0] if starts and starts[0] <= 0.001 else 0.0
    trail = duration - starts[-1] if starts and starts[-1] > lead and ends[-1] >= duration - 0.01 else 0.0
    if lead >= duration - 0.001:
        return duration, 0.0
    return lead, max(trail, 0.0)


# ---------- analyze ----------

def render_images(path, out_dir, index):
    """Images préfixées par le rang du fichier : deux sources homonymes ne s'écrasent pas."""
    out_dir.mkdir(parents=True, exist_ok=True)
    prefix = f"{index:02d}-{Path(path).stem}"
    graphs = {"wave": "showwavespic=s=1200x300:scale=sqrt:split_channels=1",
              "spectrum": "showspectrumpic=s=1024x400:fscale=log:legend=1"}
    images = []
    for kind, graph in graphs.items():
        image = out_dir / f"{prefix}.{kind}.png"
        image.unlink(missing_ok=True)
        result = run(ffmpeg("-y", "-i", str(path), "-filter_complex", f"[0:a:0]{graph}", "-frames:v", "1", str(image)))
        if result.returncode != 0 or not image.is_file():
            fail(f"image impossible à générer ({kind}) : {Path(path).name}")
        images.append(image)
    return images


def fmt(value):
    return "-inf" if value == float("-inf") else f"{value:.1f}"


def cmd_analyze(args):
    out_dir = Path(args.out) if args.out else Path(tempfile.gettempdir()) / "sfx-analyze"
    rows = []
    for index, file in enumerate(args.files, 1):
        info = probe(file)
        levels = measure(file)
        lead, trail = silences(file, info["duration"], levels["true_peak"])
        rows.append(levels)
        print(f"{Path(file).name}")
        print(f"  durée {info['duration']:.2f} s · {info['channels']} canal(aux) · {info['sample_rate']} Hz · {info['codec']}")
        print(f"  loudness : M max {fmt(levels['momentary'])} LUFS · I {fmt(levels['integrated'])} LUFS"
              f" · pic vrai {fmt(levels['true_peak'])} dBTP")
        print(f"  silence : début {lead:.3f} s · fin {trail:.3f} s")
        if not args.no_images:
            images = render_images(file, out_dir, index)
            print(f"  images : {', '.join(str(p) for p in images)}")
    if len(rows) > 1:
        def median(key):
            values = [r[key] for r in rows if not is_silent(r, key)]
            return fmt(statistics.median(values)) if values else "-inf"
        print(f"Médiane ({len(rows)} fichiers) : M max {median('momentary')} LUFS · I {median('integrated')} LUFS"
              f" · pic vrai {median('true_peak')} dBTP")


# ---------- process ----------

def cmd_process(args):
    source, output = Path(args.input), Path(args.output)
    if output.suffix.lower() not in {".wav", ".ogg"}:
        fail("sortie en .wav (SFX courts) ou .ogg (boucles, musique)")
    if output.resolve() == source.resolve():
        fail("la sortie doit être différente de l'entrée")
    metric, default_target = CATEGORIES[args.category]
    target = args.target if args.target is not None else default_target
    info = probe(source)
    is_sfx = metric == "momentary"

    with tempfile.TemporaryDirectory() as tmp:
        stage = Path(tmp) / "stage.wav"
        filters = []
        if is_sfx and not args.no_trim:
            lead, trail = silences(source, info["duration"], measure(source)["true_peak"])
            if lead >= info["duration"]:
                fail(f"fichier silencieux : {source.name}")
            end = info["duration"] - trail
            length = end - lead
            fade_out = min(FADE_OUT_MAX_S, length / 4)
            filters += [f"atrim=start={lead:.4f}:end={end:.4f}", "asetpts=PTS-STARTPTS",
                        f"afade=t=in:d={FADE_IN_S}", f"afade=t=out:st={length - fade_out:.4f}:d={fade_out:.4f}"]
        stage_cmd = ["-y", "-i", str(source), "-map", "0:a:0", "-map_metadata", "-1", "-ar", str(SAMPLE_RATE)]
        if filters:
            stage_cmd += ["-af", ",".join(filters)]
        if args.mono:
            stage_cmd += ["-ac", "1"]
        result = run(ffmpeg(*stage_cmd, "-c:a", "pcm_f32le", str(stage)))
        if result.returncode != 0:
            fail(f"traitement impossible : {result.stderr.strip()[-300:]}")

        before = measure(stage)
        if is_silent(before, metric):
            fail(f"fichier silencieux : {source.name}")
        gain = target - before[metric]
        limited = before["true_peak"] + gain > TRUE_PEAK_CEILING
        if limited:
            gain = TRUE_PEAK_CEILING - before["true_peak"]

        codec = ["-c:a", "pcm_s16le"] if output.suffix.lower() == ".wav" else ["-c:a", "libvorbis", "-q:a", "6"]
        output.parent.mkdir(parents=True, exist_ok=True)
        result = run(ffmpeg("-y", "-i", str(stage), "-af", f"volume={gain:.2f}dB", "-map_metadata", "-1",
                            "-fflags", "+bitexact", *codec, str(output)))
        if result.returncode != 0:
            fail(f"encodage impossible : {result.stderr.strip()[-300:]}")

    after = measure(output)
    out_info = probe(output)
    print(f"{output}")
    print(f"  {args.category} · {out_info['duration']:.2f} s (source {info['duration']:.2f} s)"
          f" · {out_info['channels']} canal(aux) · {out_info['sample_rate']} Hz")
    label = "M max" if is_sfx else "I"
    print(f"  {label} {fmt(after[metric])} LUFS (cible {target:.1f}) · pic vrai {fmt(after['true_peak'])} dBTP"
          f" · gain {gain:+.1f} dB")
    if limited:
        print(f"  ⚠️ gain limité par le pic : {target - after[metric]:.1f} dB sous la cible")


# ---------- fetch ----------

def check_host(url):
    parsed = urllib.parse.urlparse(url)
    host = (parsed.hostname or "").lower()
    if host in MANUAL_HOSTS:
        fail(f"{host} : téléchargement manuel uniquement (lien à donner à l'utilisateur, dossier d'entrée)")
    if parsed.scheme != "https" or host not in FETCH_HOSTS:
        fail(f"source non prise en charge : {url} (autorisées : {', '.join(sorted(FETCH_HOSTS))})")
    return host


def download(url, destination):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        check_host(response.geturl())
        size = 0
        with open(destination, "wb") as handle:
            while chunk := response.read(1024 * 1024):
                size += len(chunk)
                if size > MAX_DOWNLOAD_BYTES:
                    fail("téléchargement trop gros")
                handle.write(chunk)


def safe_name(name):
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", name).strip("._")
    return cleaned or "son"


def extract_audio(archive, target_dir):
    """Extrait uniquement les fichiers audio, sans chemin ni lien, avec plafonds de taille."""
    extracted, total = [], 0
    with zipfile.ZipFile(archive) as bundle:
        for member in bundle.infolist():
            is_symlink = (member.external_attr >> 16) & 0o170000 == 0o120000
            if member.is_dir() or is_symlink or Path(member.filename).suffix.lower() not in AUDIO_EXTENSIONS:
                continue
            total += member.file_size
            if member.file_size > MAX_INPUT_BYTES or total > MAX_EXTRACTED_BYTES:
                fail("archive trop volumineuse une fois décompressée")
            parts = [p for p in re.split(r"[\\/]+", member.filename) if p not in ("", ".", "..")]
            name = safe_name("_".join(parts[-2:]))
            destination = target_dir / name
            counter = 1
            while destination.exists():
                destination = target_dir / f"{Path(name).stem}_{counter}{Path(name).suffix}"
                counter += 1
            with bundle.open(member) as source, open(destination, "wb") as handle:
                shutil.copyfileobj(source, handle)
            extracted.append(destination)
    return extracted


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def cmd_fetch(args):
    host = check_host(args.url)
    tier, license_name = LICENSES[args.license]
    inbox = Path(args.inbox).expanduser()
    inbox.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    target_dir = Path(tempfile.mkdtemp(prefix=f"{host.removeprefix('www.')}-{stamp}-", dir=inbox))
    try:
        files = fetch_files(args.url, target_dir)
        manifest = {
            "url": args.url,
            "page": args.page,
            "author": args.author,
            "license": license_name,
            "credit_required": tier == 2,
            "date": datetime.date.today().isoformat(),
            "files": [{"name": f.name, "sha256": sha256(f)} for f in files],
        }
        (target_dir / "source.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    except OSError as error:
        shutil.rmtree(target_dir, ignore_errors=True)
        fail(f"téléchargement impossible : {args.url} ({error})")
    except BaseException:
        shutil.rmtree(target_dir, ignore_errors=True)
        raise
    print(f"{target_dir} : {len(files)} fichier(s) audio · {license_name}"
          f"{' · crédit obligatoire' if tier == 2 else ''}")
    for f in files[:20]:
        print(f"  {f.name}")
    if len(files) > 20:
        print(f"  ... {len(files) - 20} autres")


def fetch_files(url, target_dir):
    """Télécharge puis ne garde que l'audio. Tout échec lève une exception (dossier nettoyé par l'appelant)."""
    raw = target_dir / "download.part"
    download(url, raw)

    with open(raw, "rb") as handle:
        is_zip = handle.read(4) == b"PK\x03\x04"
    if is_zip:
        files = extract_audio(raw, target_dir)
        raw.unlink()
    else:
        name = safe_name(Path(urllib.parse.urlparse(url).path).name)
        if Path(name).suffix.lower() not in AUDIO_EXTENSIONS:
            fail(f"ni archive zip ni fichier audio : {url}")
        files = [raw.rename(target_dir / name)]
    if not files:
        fail("aucun fichier audio dans l'archive")
    return files


def main():
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="sfx", description="Analyse, traitement et téléchargement de sons.")
    sub = parser.add_subparsers(dest="command", required=True)

    analyze = sub.add_parser("analyze", help="mesures + images forme d'onde et spectrogramme")
    analyze.add_argument("files", nargs="+")
    analyze.add_argument("--out", help="dossier des images (défaut : <tmp>/sfx-analyze)")
    analyze.add_argument("--no-images", action="store_true", help="mesures seules (référence de mixage)")
    analyze.set_defaults(handler=cmd_analyze)

    process = sub.add_parser("process", help="coupe, fondus, normalisation, conversion")
    process.add_argument("input")
    process.add_argument("output", help=".wav (SFX courts) ou .ogg (boucles, musique)")
    process.add_argument("--category", required=True, choices=sorted(CATEGORIES))
    process.add_argument("--target", type=float, help="cible LUFS (défaut : cible de la catégorie)")
    process.add_argument("--mono", action="store_true", help="downmix mono (SFX positionnels)")
    process.add_argument("--no-trim", action="store_true", help="SFX : garder silences, sans fondus")
    process.set_defaults(handler=cmd_process)

    fetch = sub.add_parser("fetch", help="téléchargement en quarantaine (OpenGameArt, packs Kenney inclus)")
    fetch.add_argument("url")
    fetch.add_argument("--license", required=True, choices=sorted(LICENSES))
    fetch.add_argument("--page", required=True, help="page source où la licence a été lue")
    fetch.add_argument("--author", default="")
    fetch.add_argument("--inbox", default=str(Path.home() / "sfx-inbox"))
    fetch.set_defaults(handler=cmd_fetch)

    for tool in ("ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            fail(f"{tool} introuvable dans le PATH")
    args = parser.parse_args()
    args.handler(args)


if __name__ == "__main__":
    main()
