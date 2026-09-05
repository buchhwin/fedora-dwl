#!/usr/bin/env python3
"""Read GNOME/Evolution calendar events through Shell CalendarServer."""
from __future__ import annotations

import json
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402


def main() -> int:
    if len(sys.argv) != 3:
        print("[]")
        return 2
    since, until = int(sys.argv[1]), int(sys.argv[2])
    events: dict[str, dict] = {}
    loop = GLib.MainLoop()
    proxy = Gio.DBusProxy.new_for_bus_sync(
        Gio.BusType.SESSION, Gio.DBusProxyFlags.NONE, None,
        "org.gnome.Shell.CalendarServer",
        "/org/gnome/Shell/CalendarServer",
        "org.gnome.Shell.CalendarServer", None)

    def signal(_proxy, _sender, name, parameters):
        if name != "EventsAddedOrUpdated":
            return
        for event_id, summary, start, end, extras in parameters.unpack()[0]:
            events[event_id] = {
                "id": event_id, "summary": summary or "Untitled event",
                "start": start, "end": end,
                "allDay": bool(extras.get("all-day", False)),
                "color": str(extras.get("color", "")),
            }

    proxy.connect("g-signal", signal)
    proxy.call_sync("SetTimeRange", GLib.Variant("(xxb)", (since, until, True)),
                    Gio.DBusCallFlags.NONE, 5000, None)
    GLib.timeout_add(1800, lambda: (loop.quit(), GLib.SOURCE_REMOVE)[1])
    loop.run()
    print(json.dumps(sorted(events.values(), key=lambda item: item["start"]), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
