#!/usr/bin/env python3
"""Create and modify events in GNOME Evolution Data Server calendars."""
from __future__ import annotations

import json
import sys
import uuid

import gi

gi.require_version("ECal", "2.0")
gi.require_version("EDataServer", "1.2")
gi.require_version("ICalGLib", "3.0")
from gi.repository import ECal, EDataServer, ICalGLib  # noqa: E402


registry = EDataServer.SourceRegistry.new_sync(None)


def connect(uid: str):
    source = registry.ref_source(uid)
    if source is None:
        raise RuntimeError("Calendar source no longer exists")
    return ECal.Client.connect_sync(source, ECal.ClientSourceType.EVENTS, 10, None)


def calendars() -> list[dict]:
    result = []
    for source in registry.list_enabled(EDataServer.SOURCE_EXTENSION_CALENDAR):
        try:
            client = connect(source.get_uid())
            if client.is_readonly():
                continue
            parent = registry.ref_source(source.get_parent()) if source.get_parent() else None
            online = bool(parent and parent.has_extension(EDataServer.SOURCE_EXTENSION_GOA))
            result.append({"uid": source.get_uid(), "name": source.get_display_name(), "online": online})
        except Exception:
            continue
    result.sort(key=lambda item: (not item["online"], item["name"].lower()))
    return result


def caltime(timestamp: int):
    return ICalGLib.Time.new_from_timet_with_zone(timestamp, False, ICalGLib.Timezone.get_utc_timezone())


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "calendars":
        print(json.dumps(calendars(), ensure_ascii=False))
        return 0
    if len(sys.argv) == 6 and sys.argv[1] == "create":
        _, _, source_uid, summary, start, end = sys.argv
        component = ICalGLib.Component.new_vcalendar()
        event = ICalGLib.Component.new_vevent()
        event.set_uid(str(uuid.uuid4()))
        event.set_summary(summary)
        event.set_dtstart(caltime(int(start)))
        event.set_dtend(caltime(int(end)))
        component.add_component(event)
        ok, uid = connect(source_uid).create_object_sync(event, ECal.OperationFlags.NONE, None)
        if not ok:
            raise RuntimeError("Event could not be created")
        print(uid)
        return 0
    if len(sys.argv) == 6 and sys.argv[1] == "update":
        _, _, event_id, summary, start, end = sys.argv
        parts = event_id.split("\n", 2)
        if len(parts) < 2:
            raise RuntimeError("Invalid event identifier")
        source_uid, uid = parts[0], parts[1]
        rid = parts[2] if len(parts) > 2 and parts[2] else None
        client = connect(source_uid)
        ok, event = client.get_object_sync(uid, rid, None)
        if not ok:
            raise RuntimeError("Event could not be loaded")
        event.set_summary(summary)
        event.set_dtstart(caltime(int(start)))
        event.set_dtend(caltime(int(end)))
        if not client.modify_object_sync(event, ECal.ObjModType.THIS, ECal.OperationFlags.NONE, None):
            raise RuntimeError("Event could not be updated")
        return 0
    print("usage: calendar_manage.py calendars|create|update ...", file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Calendar: {error}", file=sys.stderr)
        raise SystemExit(1)
