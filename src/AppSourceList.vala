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

public class AppEditor.AppSourceList : Granite.Widgets.SourceList {
    public signal void app_selected (AppItem item);
    
    private string _search_query = "";
    public string search_query {
        get {
            return _search_query;
        }

        set {
            _search_query = value;
            refilter ();
            root.expand_all ();
        }
    }

    private bool _show_hidden_entries = false;
    public bool show_hidden_entries {
        get {
            return _show_hidden_entries;
        }

        set {
            _show_hidden_entries = value;
            refilter ();
        }
    }

    private Gee.ArrayList<AppItem> app_items;
    private CategoryItem? default_category_item;

    construct {
        app_items = new Gee.ArrayList<AppItem> ();
    }

    public AppSourceList () {
        vexpand = true;
        ellipsize_mode = Pango.EllipsizeMode.MIDDLE;

        var categories = DesktopAppManager.get_menu_cateogries ();
        int size = categories.size;
        for (int i = 0; i < size; i++) {
            var category = categories[i];
            var item = new CategoryItem (category);
            root.add (item);

            if (default_category_item == null && category.compare (DesktopAppManager.get_default_category ())) {
                default_category_item = item;
            }
        }

        set_filter_func (visible_func, true);
        root.expand_all ();

        item_selected.connect (on_item_selected);
    }

    public void add_app (DesktopApp desktop_app, bool select = false) {
        var item = new AppItem (desktop_app);
        app_items.add (item);

        var category = get_category_for_app_info (desktop_app);
        category.add (item);

        if (select) {
            selected = item;
        }

        desktop_app.changed.connect (() => on_item_desktop_app_changed (item));
    }

    public void remove_app (DesktopApp desktop_app) {
        foreach (var app_item in app_items) {
            if (app_item.desktop_app.compare (desktop_app)) {
                app_item.parent.remove (app_item);
                app_items.remove (app_item);
                break;
            }
        }
    }

    public void select_desktop_id (string desktop_id) {
        foreach (var app_item in app_items) {
            if (app_item.desktop_app.get_basename () == desktop_id) {
                selected = app_item;
                break;
            }
        }
    }

    private CategoryItem get_category_for_app_info (DesktopApp desktop_app) {
        CategoryItem category_item = default_category_item;

        var app_category = desktop_app.get_main_category ();
        var collection = (Gee.AbstractCollection<Granite.Widgets.SourceList.Item>)root.children;
        foreach (var item in collection) {
            if (item is CategoryItem) {
                var cat_item = (CategoryItem)item;
                if (cat_item.category.compare (app_category)) {
                    category_item = cat_item;
                    break;
                }
            }
        }

        return category_item;
    }

    private bool visible_func (Granite.Widgets.SourceList.Item item) {
        bool visible = false;

        if (item is AppItem) {
            var app_item = (AppItem)item;
            visible = get_app_item_should_show (app_item);
        } else if (item is CategoryItem) {
            // Unfortunately, this has to be done, since after refilter ()
            // Granite still shows all categories even without any items
            var cat_item = (CategoryItem)item;
            var collection = (Gee.AbstractCollection<Granite.Widgets.SourceList.Item>)cat_item.children;
            foreach (var subitem in collection) {
                if (subitem is AppItem) {
                    var app_item = (AppItem)subitem;
                    if (get_app_item_should_show (app_item)) {
                        visible = true;
                        break;
                    }
                }
            }
        }

        return visible;
    }

    private bool get_app_item_should_show (AppItem app_item) {
        bool should_show = show_hidden_entries || app_item.desktop_app.get_should_show ();
        return app_item.name.down ().contains (search_query.down ()) && should_show;
    }

    private void on_item_selected (Granite.Widgets.SourceList.Item? item)  {
        if (item != null && item is AppItem) {
            app_selected ((AppItem)item);
        }
    }

    private void on_item_desktop_app_changed (AppItem item) {
        var current_category_item = item.parent as CategoryItem;
        if (current_category_item == null) {
            return;
        }

        var desktop_app = item.desktop_app;
        var new_category = get_category_for_app_info (desktop_app);
        if (!current_category_item.category.compare (new_category.category)) {
            current_category_item.remove (item);
            new_category.add (item);
            selected = item;
        }
    }
}
