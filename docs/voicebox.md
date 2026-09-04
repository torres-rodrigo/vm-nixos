# Voicebox Integration Plan

## Goal And Recommendation

Voicebox is a local-first AI voice studio for speech generation, voice cloning,
transcription, captures, stories, REST automation, and MCP-based agent speech.
It is interesting for this workstation because it can cover the text-to-speech
and voice-agent side that Omarchy's Voxtype investigation did not cover.

The right first step for this NixOS configuration is not a native desktop
package. Current upstream docs say Linux desktop builds are still coming, and
this nixpkgs set does not expose a `voicebox` package. Start with the
containerized Voicebox web UI/API on `conquest`, bound to localhost at
`127.0.0.1:17493`.

Recommended decision:

1. Use a containerized Voicebox server first.
2. Keep the Voicebox source checkout outside `/etc/nixos`, for example
   `~/src/voicebox`.
3. Add only the container runtime and host integration to this repo.
4. Keep the service localhost-only unless explicit authentication is added.
5. Treat native source/Tauri builds as an experimental path, not the default
   workstation integration.

Sources:

- <https://github.com/jamiepine/voicebox>
- <https://docs.voicebox.sh/>
- <https://docs.voicebox.sh/overview/installation>
- <https://docs.voicebox.sh/overview/docker>
- <https://docs.voicebox.sh/overview/gpu-acceleration>
- <https://docs.voicebox.sh/overview/dictation>
- <https://docs.voicebox.sh/overview/mcp-server>

## What Voicebox Provides

Voicebox is broader than a simple TTS command. The useful capabilities to track
for this system are:

| Capability | What it does | Fit for this config |
| --- | --- | --- |
| Text-to-speech | Generates speech from text with several engines. | Good fit, especially through web UI, REST, or MCP. |
| Voice cloning | Creates voice profiles from short voice samples. | Useful, but requires careful consent and storage hygiene. |
| Preset voices | Lets users generate speech without cloning first. | Best starting point because it avoids personal voice data setup. |
| Transcription | Uses Whisper-backed speech-to-text. | Useful for files and automation; separate from current OCR work. |
| Captures | Stores audio and transcripts together. | Useful for reviewing generated/transcribed material. |
| Stories editor | Multi-track timeline for conversations or narrative audio. | Nice to have, not core workstation plumbing. |
| REST API | Local HTTP API for scripts and tools. | Good integration point for Mango scripts or CLI helpers. |
| MCP server | Lets MCP-aware agents call Voicebox. | Good fit for Codex/agent workflows if kept localhost-only. |
| Dictation | Push-to-talk speech input into apps. | Not ready for Linux auto-paste/global hotkey usage yet. |

The most useful first workflow is agent or script speech output:

```console
curl -X POST http://127.0.0.1:17493/speak \
  -H 'Content-Type: application/json' \
  -H 'X-Voicebox-Client-Id: shell' \
  -d '{"text":"Build complete."}'
```

Do not wire this into noisy system events by default. TTS should be explicit
until the resource cost and annoyance level are understood.

## Current Linux Support Status

Upstream currently documents macOS and Windows desktop downloads, with Linux
desktop builds still pending. For Linux, the supported practical routes are:

1. Docker/container deployment with a web UI served by the backend.
2. Source build using Rust, Bun, Python, Just, and Tauri system dependencies.

The container route is the better NixOS fit for now because it avoids packaging
the full Tauri desktop app and its Python model stack into this flake. It also
keeps the large, fast-moving ML dependency graph outside the main workstation
closure.

The tradeoff is that the container still has a large build/model footprint.
Expect multiple gigabytes for Python, PyTorch, model dependencies, and cached
models.

## Recommended NixOS Installation Plan

### Stage 1: Add Container Runtime

Add a focused reusable NixOS module for containers, for example
`modules/nixos/containers.nix`.

Preferred first runtime: Docker.

Reasoning:

- Upstream documents `docker compose up` directly.
- It reduces the number of translation issues while validating Voicebox.
- GPU documentation assumes Docker-style compose examples.

Alternative runtime: Podman.

Podman is attractive for rootless operation, but it adds compose compatibility
questions that should not be solved during the first Voicebox validation. Once
Voicebox works, a Podman migration can be evaluated.

Initial module shape:

```nix
{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
```

Import this module only on `conquest` at first. Do not add it to `war` unless
the VM needs container validation.

After rebuild and activation, add user `r` to the Docker group if the module
does not already do that explicitly:

```nix
users.users.r.extraGroups = [
  "docker"
];
```

Security note: membership in the Docker group is effectively root-equivalent.
If that is not acceptable, use `sudo docker compose ...` or revisit Podman
rootless before enabling Docker for daily use.

### Stage 2: Clone Voicebox Outside The NixOS Repo

Keep the application checkout outside `/etc/nixos`:

```console
mkdir -p ~/src
cd ~/src
git clone https://github.com/jamiepine/voicebox.git
cd voicebox
```

Do not vendor this repository into `/etc/nixos`. The checkout will contain
dependency state, build outputs, downloaded model metadata, generated audio,
and other application files that do not belong in this NixOS flake.

### Stage 3: Start CPU-Only First

Bring up the upstream compose stack without GPU acceleration first:

```console
cd ~/src/voicebox
docker compose up
```

Then open:

```text
http://127.0.0.1:17493
```

The first build can be slow because it builds the frontend, installs Python
dependencies, and prepares the backend. The first generation with a model can
also be slow because model files are downloaded on demand.

The upstream compose defaults are useful and should be preserved:

- Bind to `127.0.0.1:17493`, not `0.0.0.0`.
- Persist `/app/data`.
- Persist generated output.
- Persist the Hugging Face cache.
- Keep resource limits explicit.

If the upstream compose file does not already place generated output somewhere
convenient, adjust the local checkout's compose override, not the NixOS repo.

Suggested local-only override path:

```text
~/src/voicebox/docker-compose.override.yml
```

Suggested override intent:

```yaml
services:
  voicebox:
    ports:
      - "127.0.0.1:17493:17493"
    volumes:
      - ./output:/app/data/generations
      - voicebox-data:/app/data
      - huggingface-cache:/home/voicebox/.cache/huggingface
    environment:
      - LOG_LEVEL=info
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: 8G
```

Keep the first run boring. Confirm the UI/API works before adding GPU,
systemd, reverse proxying, or agent integration.

### Stage 4: Add A User Service After Manual Validation

Once manual `docker compose up` works, add a user-level systemd service rather
than an always-on system service. Voicebox is heavy enough that it should not
start unless the user wants it.

Recommended service behavior:

- Manual start by default: `systemctl --user start voicebox`.
- No `WantedBy = [ "default.target" ]` at first.
- Working directory points to `/home/r/src/voicebox`.
- ExecStart runs Docker Compose in foreground mode.
- Restart only on failure after the initial setup is stable.

Potential Home Manager service:

```nix
systemd.user.services.voicebox = {
  Unit = {
    Description = "Voicebox local voice studio";
    After = [ "graphical-session.target" ];
  };

  Service = {
    WorkingDirectory = "/home/r/src/voicebox";
    ExecStart = "${pkgs.docker-compose}/bin/docker-compose up";
    ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    Restart = "on-failure";
    RestartSec = 5;
  };
};
```

This should be added only after deciding where container runtime ownership
lives in this repo. If Docker Compose v2 is used through the Docker CLI, prefer
`docker compose up` over the standalone `docker-compose` binary and adjust the
package/command accordingly.

### Stage 5: Optional Launcher Integration

After the service works, add one or two Mango bindings or launcher entries:

| Action | Command |
| --- | --- |
| Start Voicebox | `systemctl --user start voicebox` |
| Stop Voicebox | `systemctl --user stop voicebox` |
| Open Voicebox UI | `xdg-open http://127.0.0.1:17493` |

Do not start Voicebox from Mango automatically in the first version. It should
remain opt-in because model servers and ML runtimes are not cheap idle
dependencies.

## GPU Acceleration Notes

`conquest` already uses the NVIDIA hybrid graphics module, so CUDA is the most
likely acceleration target. Add GPU support only after CPU-only Voicebox works.

The relevant package exists in nixpkgs:

```text
nvidia-container-toolkit
```

Possible NixOS additions:

```nix
{
  hardware.nvidia-container-toolkit.enable = true;
}
```

Then update the local Voicebox compose override with NVIDIA device reservation
once the toolkit is active:

```yaml
services:
  voicebox:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Validation commands:

```console
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
curl http://127.0.0.1:17493/health
```

Inside Voicebox, verify the backend from Settings or from `/health`. Upstream
documents `backend_type`, `backend_variant`, and GPU compatibility warnings in
the health response.

Performance guidance:

- CPU inference works but can be much slower.
- Use smaller/lighter engines first.
- Kokoro is the best first model when minimizing download and runtime cost.
- LuxTTS is documented as strong for CPU speed.
- Larger engines such as Qwen 1.7B or TADA 3B should wait until GPU
  acceleration is working.
- Keep at least 10 GB free for models and generated data; more is better if
  testing multiple engines.

## Usage Workflow

### First Launch

1. Start the container:

   ```console
   cd ~/src/voicebox
   docker compose up
   ```

2. Open the UI:

   ```text
   http://127.0.0.1:17493
   ```

3. Confirm the backend/server indicator is healthy.

4. Pick a small preset voice or lightweight engine before downloading large
   models.

5. Generate a short sentence and confirm playback works.

### Creating A Voice Profile

Voice profiles can be created from uploaded audio or recorded samples.

Recommended sample rules:

- Use clean audio with minimal background noise.
- Use 10-30 seconds for the first sample.
- Keep a consistent speaking tone.
- Add more samples only if quality is not good enough.
- Do not clone voices without consent.

Voice profile data should be treated as personal data. Do not commit samples,
generated voice profiles, model caches, or output audio into this repository.

### Generating Speech

Basic workflow:

1. Open the Generate tab.
2. Select a profile or preset voice.
3. Choose a lightweight engine first.
4. Enter text.
5. Generate, preview, then download only if needed.

The generated audio also appears in Voicebox history/captures. Use that instead
of scattering exported files across the home directory.

### Stories

The Stories editor is useful for multi-speaker output, podcasts, dialogue, or
long-form generated audio. It should not affect the NixOS integration plan
except for storage: generated media can grow quickly.

Keep large exports outside the NixOS repo.

## MCP And API Integration

Voicebox exposes MCP over local HTTP:

```text
http://127.0.0.1:17493/mcp
```

The useful MCP tools are:

| Tool | Purpose |
| --- | --- |
| `voicebox.speak` | Speak text in a selected voice profile. |
| `voicebox.transcribe` | Transcribe an audio file or base64 audio. |
| `voicebox.list_captures` | List recent captures and transcripts. |
| `voicebox.list_profiles` | List available voice profiles. |

For HTTP-capable MCP clients, use:

```json
{
  "mcpServers": {
    "voicebox": {
      "url": "http://127.0.0.1:17493/mcp",
      "headers": {
        "X-Voicebox-Client-Id": "codex"
      }
    }
  }
}
```

The `X-Voicebox-Client-Id` value is not a secret. It identifies the client so
Voicebox can remember profile/engine bindings per client.

For simple scripts, use the REST API instead of MCP:

```console
curl -X POST http://127.0.0.1:17493/speak \
  -H 'Content-Type: application/json' \
  -H 'X-Voicebox-Client-Id: scripts' \
  -d '{"text":"Screenshot OCR finished.","engine":"kokoro","language":"en"}'
```

Potential later Mango integration:

- Add a script that speaks selected clipboard text.
- Add a script that reads an OCR result aloud.
- Add a script that announces long command completion manually.

Do not add automatic global announcements initially. They are distracting and
can leak private content into speakers.

Security notes:

- Keep Voicebox bound to `127.0.0.1`.
- The local API has no authentication today.
- Any local process that can reach the port can request speech or access API
  behavior.
- Do not expose the service to the LAN without a reverse proxy and
  authentication.
- Be especially careful with `voicebox.transcribe` against local file paths on
  shared machines.

## Dictation Status On Linux

Voicebox dictation is promising but should not be the first Linux integration
target here.

Current upstream documentation says the Linux dictation path is not yet in the
current release. The macOS and Windows paths handle global hotkeys and
synthetic paste, while Linux `uinput`, AT-SPI, and Wayland paste support are
still planned.

Implications for this repo:

1. Do not add a Mango dictation keybinding for Voicebox yet.
2. Do not replace the Omarchy/Voxtype investigation with Voicebox dictation
   until Linux support lands.
3. Use Voicebox now for speech generation, voice profiles, transcription,
   REST, and MCP.
4. Revisit dictation after upstream Linux support exists and can be tested in
   Mango/Wayland.

If dictation becomes urgent before Voicebox supports Linux well, evaluate a
separate lightweight Wayland dictation stack instead of forcing Voicebox into
that role.

## Native Source Build Option

The native build path is useful for development or testing unreleased Linux
desktop support. It is not the recommended first workstation integration.

Upstream source build requirements include:

- Git
- Rust
- Bun
- Python 3.11+
- Just
- Tauri Linux system dependencies

Basic upstream flow:

```console
git clone https://github.com/jamiepine/voicebox.git
cd voicebox
just setup
just dev
```

For a release build:

```console
just build
```

Expected output is under:

```text
tauri/src-tauri/target/release/bundle/
```

NixOS packaging notes:

- Add development dependencies only if actively working on Voicebox.
- Keep the checkout in `~/src/voicebox`.
- Do not add generated dependency directories or build outputs to this repo.
- Prefer `nix develop` or a local dev shell only after the source build path is
  actually chosen.
- Native packaging should be deferred until upstream Linux artifacts are stable
  or the container path proves insufficient.

Possible future native module direction:

1. Add a dev shell with Rust, Bun, Python 3.11, Just, pkg-config, and Tauri
   system libraries.
2. Build from source outside the NixOS repo.
3. Test the desktop app under Mango/Wayland.
4. Only then consider a flake package or overlay.

## Validation And Troubleshooting

### Documentation Change Validation

Creating this document does not require a NixOS rebuild.

Useful checks:

```console
ls docs/voicebox.md
sed -n '1,220p' docs/voicebox.md
```

### Future NixOS Validation

When the container module is implemented:

```console
nix flake check --no-build
```

Build host configurations only after confirming with the user, following the
project rule for rebuilds.

### Runtime Validation

After activating the container runtime:

```console
docker --version
docker compose version
cd ~/src/voicebox
docker compose up
```

Then check:

```console
curl http://127.0.0.1:17493/health
```

Expected result:

- The endpoint responds.
- The UI opens at `http://127.0.0.1:17493`.
- The first small generation succeeds.
- Generated audio can be played.
- Model cache persists after restarting the container.

### Common Problems

| Problem | Likely cause | Fix |
| --- | --- | --- |
| Port `17493` is busy | Another Voicebox/server process is running. | Stop the old service or change the local port mapping. |
| Models download every run | Hugging Face cache is not persisted. | Check the compose volume for `/home/voicebox/.cache/huggingface`. |
| UI shows only API JSON | Frontend build failed or static UI is missing. | Rebuild the container and inspect build logs. |
| Container is killed | Memory limit is too low. | Increase compose memory limit or use a smaller model. |
| Very slow generation | CPU-only inference or oversized model. | Start with Kokoro/LuxTTS or enable CUDA. |
| GPU not detected | NVIDIA container runtime not enabled/configured. | Validate `nvidia-container-toolkit` and `docker run --gpus all ... nvidia-smi`. |
| MCP client cannot connect | Voicebox backend is not running. | Start Voicebox and test `/health` first. |

## Final Recommendation

Implement Voicebox in this order:

1. Add a Docker container module for `conquest`.
2. Manually clone and run Voicebox from `~/src/voicebox`.
3. Validate CPU-only web UI and a small TTS generation.
4. Add optional user service for manual start/stop.
5. Add NVIDIA container toolkit and CUDA compose settings.
6. Wire MCP only after local generation and profile selection work.
7. Revisit Linux dictation and native desktop packaging later.

This keeps the NixOS system explicit and avoids turning a large ML application
into a baseline dependency before its runtime cost and Linux support are known.
