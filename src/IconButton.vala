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

public class AppEditor.IconButton : Gtk.MenuButton {
    public signal void changed ();

    public Icon icon {
        set {
            icon_image.gicon = value;
            ignore_entry_changed = true;
            entry.text = icon.to_string ();
            ignore_entry_changed = false;
        }

        owned get {
            return icon_image.gicon;
        }
    }

    private Gtk.Image icon_image;
    private Gtk.Entry entry;

    private Gtk.Menu method_menu;
    private Gtk.MenuItem file_menu_item;
    private Gtk.MenuItem name_menu_item;

    private bool ignore_entry_changed = false;

    private static Icon default_icon;

    private const string BUTTON_CSS = """
        .button {
            border-width: 1px;
            border-color: #c8c8c8;
        }
    """;

    private const string BUTTON_CSS_322 = """
        button {
            border-width: 1px;
            border-color: #c8c8c8;
        }
    """;

    static construct {
        default_icon = new ThemedIcon ("application-x-executable");
    }

    construct {
        string css;
        if (Application.has_gtk_322 ()) {
            css = BUTTON_CSS_322;
        } else {
            css = BUTTON_CSS;
        }

        Granite.Widgets.Utils.set_theming (this, css, "flat", Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        icon_image = new Gtk.Image ();
        icon_image.pixel_size = 64;
        image = icon_image;

        entry = new PersistentPlaceholderEntry ();
        entry.width_request = 200;
        entry.margin = 6;
        entry.placeholder_text = _("Icon name or path to an image");
        entry.changed.connect (on_entry_changed);
        entry.show_all ();

        file_menu_item = new Gtk.MenuItem.with_label (_("Choose from file"));
        file_menu_item.activate.connect (on_file_menu_item_activate);
        file_menu_item.show_all ();

        name_menu_item = new Gtk.MenuItem.with_label (_("Choose from available icons"));
        name_menu_item.activate.connect (on_name_menu_item_activate);
        name_menu_item.show_all ();

        method_menu = new Gtk.Menu ();
        method_menu.add (file_menu_item);
        method_menu.add (name_menu_item);

        set_popup (method_menu);
    }

    private void on_file_menu_item_activate () {
        var all_filter = new Gtk.FileFilter ();
        all_filter.set_filter_name (_("All Files"));
        all_filter.add_pattern ("*");
        
        var image_filter = new Gtk.FileFilter ();
        image_filter.set_filter_name (_("Images"));
        image_filter.add_mime_type ("image/*");

        var file_chooser = new Gtk.FileChooserDialog (
            _("Select an image"), null, Gtk.FileChooserAction.OPEN,
            "_Cancel",
            Gtk.ResponseType.CANCEL,
            "_Open",
            Gtk.ResponseType.ACCEPT
        );

        file_chooser.add_filter (image_filter);
        file_chooser.add_filter (all_filter);

        file_chooser.response.connect ((response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                string uri = file_chooser.get_uri ();
                var file = File.new_for_uri (uri);
                set_gicon (new FileIcon (file));
            }

            file_chooser.destroy ();
        });

        file_chooser.run ();
    }

    private void on_name_menu_item_activate () {
        var icon_chooser_dialog = new IconChooserDialog ();
        icon_chooser_dialog.selected.connect ((icon_name) => set_gicon (new ThemedIcon (icon_name)));

        icon_chooser_dialog.show_all ();
    }

    private void set_gicon (Icon icon) {
        icon_image.gicon = icon;
        changed ();
    }

    private void on_entry_changed () {
        if (ignore_entry_changed) {
            return;
        }

        string text = entry.text;
        if (text.has_prefix (Path.DIR_SEPARATOR_S)) {
            var file = File.new_for_path (text);
            if (file.query_file_type (FileQueryInfoFlags.NONE) == FileType.REGULAR) {
                icon_image.gicon = new FileIcon (file);
            } else {
                icon_image.gicon = default_icon;
            }
        } else {
            var icon_theme = Gtk.IconTheme.get_default ();
            if (icon_theme.has_icon (text)) {
                icon_image.gicon = new ThemedIcon (text);
            } else {
                icon_image.gicon = default_icon;
            }
        }

        changed ();
    }
}
