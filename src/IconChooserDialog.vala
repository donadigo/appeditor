/*-
 * Copyright 2021 Adam Bieńkowski <donadigos159@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

public class AppEditor.IconChooserDialog : Gtk.Dialog {
    public signal void selected (string icon_name);

    private IconListBox icon_list_box;
    private Gtk.SearchEntry search_entry;
    private Gtk.Button choose_button;
    private Gtk.Button cancel_button;

    construct {
        cancel_button = (Gtk.Button)add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        choose_button = (Gtk.Button)add_button (_("Choose"), Gtk.ResponseType.ACCEPT);
        choose_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        choose_button.sensitive = false;

        icon_list_box = new IconListBox ();
        icon_list_box.row_selected.connect (on_row_selected);
        icon_list_box.row_activated.connect (on_row_activated);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (icon_list_box);
        scrolled.edge_overshot.connect (on_edge_overshot);

        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Search icons…");
        search_entry.margin_bottom = search_entry.margin_start = search_entry.margin_end = 12;
        search_entry.hexpand = true;
        search_entry.search_changed.connect (on_search_entry_changed);

        unowned Gtk.Box content_area = get_content_area ();
        content_area.add (search_entry);
        content_area.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        content_area.add (scrolled);
        content_area.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
    }

    public IconChooserDialog () {
        Object (
            title: _("Choose an icon from the list"),
            deletable: false,
            width_request: 500,
            height_request: 650
        );
    }

    public override void response (int response_id) {
        if (response_id == Gtk.ResponseType.ACCEPT) {
            string? icon_name = icon_list_box.get_selected_icon_name ();
            if (icon_name != null) {
                selected (icon_name);
            }
        }

        destroy ();
    }

    private void on_row_selected (Gtk.ListBoxRow? row) {
        choose_button.sensitive = row != null;
    }

    private void on_row_activated (Gtk.ListBoxRow row) {
        response (Gtk.ResponseType.ACCEPT);
    }

    private void on_edge_overshot (Gtk.PositionType position) {
        if (position == Gtk.PositionType.BOTTOM) {
            icon_list_box.load_next_icons ();
        }
    }

    private void on_search_entry_changed () {
        icon_list_box.search (search_entry.text);
        icon_list_box.invalidate_filter ();
    }
}
