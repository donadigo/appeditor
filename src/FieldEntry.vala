/*-
 * Copyright (c) 2017 Adam Bieńkowski
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class AppEditor.FieldEntry : Gtk.Box {
    private const string ENTRY_CSS = """
        .entry.flat {
        	background-color: rgba(0,0,0,0);
        }

        .entry.flat:selected,
        .entry.flat:selected:focus {
        	background-color: @colorAccent;
        }
    """;

    public Gtk.Entry entry { get; construct; }

    private Gtk.Revealer revealer;

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        Granite.Widgets.Utils.set_theming (entry, ENTRY_CSS, Gtk.STYLE_CLASS_FLAT, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        entry.changed.connect (update_header_visibility);
        entry.focus_in_event.connect (on_entry_focus_in_event);
        entry.focus_out_event.connect (on_entry_focus_out_event);

        var header_label = new Gtk.Label (entry.placeholder_text);
        header_label.get_style_context ().add_class ("h4");

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        revealer.halign = Gtk.Align.START;
        revealer.valign = Gtk.Align.START;
        revealer.add (header_label);

        add (revealer);
        add (entry);
    }

    public FieldEntry (Gtk.Entry entry) {
        Object (entry: entry);
    }

    private void update_header_visibility () {
        revealer.reveal_child = entry.text_length > 0 && entry.has_focus;
    }

    private bool on_entry_focus_in_event (Gdk.EventFocus event) {
        update_header_visibility ();
        return Gdk.EVENT_PROPAGATE;
    }

    private bool on_entry_focus_out_event (Gdk.EventFocus event) {
        update_header_visibility ();
        return Gdk.EVENT_PROPAGATE;
    }
}
