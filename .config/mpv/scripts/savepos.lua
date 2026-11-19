local saved

mp.add_key_binding(nil, "save", function()
    saved = mp.get_property_number("time-pos")
    mp.osd_message(("Position gespeichert: %s"):format(mp.format_time(saved)))
end)

mp.add_key_binding(nil, "restore", function()
    if not saved then
        mp.osd_message("Keine Position gespeichert")
        return
    end
    mp.commandv("seek", saved, "absolute+exact")
    mp.osd_message(("Zurück zu %s"):format(mp.format_time(saved)))
end)
