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

public class AppEditor.CategoryComboBox : Gtk.ComboBox {
    private Gtk.ListStore list_store;
    private Gtk.TreeIter? active_iter;

    construct {
        list_store = new Gtk.ListStore (3, typeof (string), typeof (unowned string), typeof (string));
        model = list_store;

        var categories = DesktopAppManager.get_menu_cateogries ();

        Gtk.TreeIter iter;
        foreach (var category in categories) {
            list_store.append (out iter);
            list_store.@set (iter, 0, category.id, 1, category.name, 2, category.icon_name);
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        pack_start (pixbuf_cell, false);
        add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        pack_start (text_cell, true);
        add_attribute (text_cell, "text", 1);
    }

    public void set_current_desktop_app (DesktopApp desktop_app) {
        var active_category = desktop_app.get_main_category ();

        Gtk.TreeIter iter;
        for (bool next = list_store.get_iter_first (out iter); next; next = list_store.iter_next (ref iter)) {
            Value id;
            list_store.get_value (iter, 0, out id);

            if (((string)id) == active_category.id) {
                active_iter = iter;
            }
        }

        set_active_iter (active_iter);
    }

    public string? get_selected_category_id () {
        Gtk.TreeIter iter;
        if (!get_active_iter (out iter)) {
            return null;
        }

        Value id;
        list_store.get_value (iter, 0, out id);

        return (string)id;
    }
}
