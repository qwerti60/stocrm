from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

REPO = Path(__file__).resolve().parents[2]

PAGES = {
    "/": "docs/index.html",
    "/index.html": "docs/index.html",
    "/qa.html": "docs/qa.html",
    "/manager-guide.html": "docs/manager-guide.html",
    "/user-guide.html": "docs/user-guide.html",
    "/DEVELOPMENT.md": "docs/DEVELOPMENT.md",
    "/plan.html": "plan.html",
    "/tz.html": "tz.html",
    "/kp.html": "kp.html",
    "/dogovor.html": "dogovor.html",
}


def mount_site(app: FastAPI) -> None:
    def make(rel: str):
        def handler():
            path = REPO / rel
            if not path.is_file():
                raise HTTPException(404)
            mime = "text/markdown; charset=utf-8" if path.suffix == ".md" else None
            return FileResponse(path, media_type=mime)

        return handler

    for url, rel in PAGES.items():
        app.add_api_route(url, make(rel), methods=["GET"], include_in_schema=False, name=f"site{url.replace('/', '_') or '_root'}")

    shots = REPO / "screenshots"
    if shots.is_dir():
        app.mount("/screenshots", StaticFiles(directory=shots), name="screenshots")
    dist = REPO / "dist"
    if dist.is_dir():
        app.mount("/apk", StaticFiles(directory=dist), name="apk")
    web = REPO / "prototype" / "build" / "web"
    if web.is_dir():
        app.mount("/app", StaticFiles(directory=web, html=True), name="app")
