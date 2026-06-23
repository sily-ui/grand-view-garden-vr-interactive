#!/usr/bin/env python3
"""Generate local Godot audio assets with DashScope fun-music-v1.

Usage:
  python tools/generate_fun_music.py

The script reads assets/config/dashscope_music_config.json for DashScope
credentials, then writes configured files under assets/audio/.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = REPO_ROOT / "assets" / "audio" / "fun_music_manifest.json"
DEFAULT_CONFIG = REPO_ROOT / "assets" / "config" / "dashscope_music_config.json"
API_BASE_URL = "https://dashscope.aliyuncs.com/api/v1/services/audio/music/generation"


def request_sse(url: str, api_key: str, payload: dict[str, Any]) -> list[dict[str, Any]]:
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(url, data=data, method="POST")
    request.add_header("Authorization", f"Bearer {api_key}")
    request.add_header("Content-Type", "application/json")
    request.add_header("X-DashScope-SSE", "enable")
    try:
        with urllib.request.urlopen(request, timeout=900) as response:
            body = response.read().decode("utf-8", errors="replace")
            return parse_sse_events(body)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(format_http_error(exc.code, body, url)) from exc


def parse_sse_events(body: str) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for raw_event in body.replace("\r\n", "\n").split("\n\n"):
        data_lines: list[str] = []
        for line in raw_event.split("\n"):
            if line.startswith("data:"):
                data_lines.append(line[5:].strip())
        if not data_lines:
            continue
        data_text = "\n".join(data_lines)
        if data_text == "[DONE]":
            continue
        try:
            event = json.loads(data_text)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict):
            events.append(event)
    if not events and body.strip():
        try:
            event = json.loads(body)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Could not parse DashScope SSE response: {body[:1000]}") from exc
        if isinstance(event, dict):
            events.append(event)
    return events


def format_http_error(status_code: int, body: str, url: str) -> str:
    message = f"HTTP {status_code}: {body}"
    if status_code == 401:
        return (
            f"{message}\n"
            "请检查 api_key 是否复制完整、是否属于阿里云百炼 DashScope，"
            "以及 key 所属地域是否和 api_base_url 匹配。"
        )
    if status_code == 403:
        return (
            f"{message}\n"
            "请求已到达 DashScope，但账号无权调用当前模型或接口。请检查：\n"
            "1. 百炼控制台是否已开通 fun-music-v1 / Fun-Music 模型权限；\n"
            "2. 当前 API Key 所在业务空间是否有该模型调用权限；\n"
            "3. 账号是否欠费、免费额度是否用完即停；\n"
            "4. api_base_url 是否和 API Key 地域一致。当前 URL: "
            f"{url}"
        )
    if status_code == 404:
        return f"{message}\n请检查 api_base_url / task_url_template 是否为 Fun-Music 文档中的正确接口路径。"
    return message


def generate_music(asset: dict[str, Any], model: str, negative_prompt: str, api_key: str, api_base_url: str) -> dict[str, Any]:
    prompt = str(asset["prompt"])
    if negative_prompt:
        prompt = f"{prompt}\n负面要求：{negative_prompt}"
    payload = {
        "model": model,
        "input": {
            "prompt": prompt,
            "gender": str(asset.get("gender", "female")),
        },
    }
    events = request_sse(api_base_url, api_key, payload)
    if not events:
        raise RuntimeError(f"No SSE events returned for {asset['id']}")
    last_event = events[-1]
    code = str(last_event.get("code", ""))
    if code and code.lower() not in {"success", "ok"}:
        raise RuntimeError(f"DashScope returned error for {asset['id']}: {last_event}")
    return last_event


def find_audio_url(response: dict[str, Any]) -> str:
    candidates: list[Any] = [response, response.get("output", {})]
    output = response.get("output", {})
    for key in ("results", "audios", "music", "data", "choices"):
        value = output.get(key)
        if isinstance(value, list):
            candidates.extend(value)
        elif isinstance(value, dict):
            candidates.append(value)
    for item in candidates:
        if not isinstance(item, dict):
            continue
        for key in ("audio_url", "url", "music_url", "file_url", "download_url", "audio"):
            value = item.get(key)
            if isinstance(value, str) and value.startswith(("http://", "https://")):
                return value
    raise RuntimeError(f"Could not find audio URL in response: {response}")


def download_file(url: str, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=120) as response:
        output_path.write_bytes(response.read())


def load_config(config_path: Path) -> dict[str, str]:
    if not config_path.exists():
        raise RuntimeError(f"Missing config file: {config_path}")
    raw_config = json.loads(config_path.read_text(encoding="utf-8"))
    if not isinstance(raw_config, dict):
        raise RuntimeError("Config file must contain a JSON object.")
    api_key = str(raw_config.get("api_key", "")).strip()
    if not api_key:
        raise RuntimeError(f"Please fill api_key in {config_path}")
    return {
        "api_key": api_key,
        "api_base_url": str(raw_config.get("api_base_url", API_BASE_URL)).strip() or API_BASE_URL,
    }


def generate_assets(config_path: Path, manifest_path: Path, overwrite: bool, only: set[str] | None) -> None:
    config = load_config(config_path)

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    model = str(manifest.get("model", "fun-music-v1"))
    negative_prompt = str(manifest.get("negative_prompt", ""))
    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        raise RuntimeError("Manifest field 'assets' must be a list.")

    for asset in assets:
        if not isinstance(asset, dict):
            continue
        asset_id = str(asset.get("id", ""))
        if only and asset_id not in only:
            continue
        output_path = REPO_ROOT / str(asset["output"])
        if output_path.exists() and not overwrite:
            print(f"skip existing: {output_path.relative_to(REPO_ROOT)}")
            continue
        print(f"submit: {asset_id}")
        response = generate_music(
            asset,
            model,
            negative_prompt,
            config["api_key"],
            config["api_base_url"],
        )
        audio_url = find_audio_url(response)
        print(f"download: {asset_id} -> {output_path.relative_to(REPO_ROOT)}")
        download_file(audio_url, output_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate DashScope fun-music-v1 audio assets.")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--only", nargs="*", help="Asset ids to generate, default: all")
    args = parser.parse_args()
    try:
        generate_assets(args.config, args.manifest, args.overwrite, set(args.only) if args.only else None)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
