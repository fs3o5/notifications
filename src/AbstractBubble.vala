/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/

public class Notifications.AbstractBubble : Gtk.Window {
    public signal void closed (uint32 reason);

    protected Gtk.Stack content_area;
    protected Gtk.HeaderBar headerbar;
    protected Gtk.Grid draw_area;

    private Gtk.Revealer revealer;
    private uint timeout_id;

    construct {
        content_area = new Gtk.Stack ();
        content_area.transition_type = Gtk.StackTransitionType.SLIDE_DOWN;
        content_area.vhomogeneous = false;

        draw_area = new Gtk.Grid ();
        draw_area.hexpand = true;
        draw_area.margin = 16;
        draw_area.get_style_context ().add_class ("draw-area");
        draw_area.add (content_area);

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        close_button.halign = close_button.valign = Gtk.Align.START;
        close_button.get_style_context ().add_class ("close");

        var close_revealer = new Gtk.Revealer ();
        close_revealer.reveal_child = false;
        close_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        close_revealer.add (close_button);

        var overlay = new Gtk.Overlay ();
        overlay.add (draw_area);
        overlay.add_overlay (close_revealer);

        revealer = new Gtk.Revealer ();
        revealer.reveal_child = true;
        revealer.transition_duration = 195;
        revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        revealer.add (overlay);

        var label = new Gtk.Grid ();

        default_height = 0;
        default_width = 332;
        resizable = false;
        type_hint = Gdk.WindowTypeHint.NOTIFICATION;
        add (revealer);
        get_style_context ().add_class ("notification");
        set_titlebar (label);

        close_button.clicked.connect (() => {
            closed (Notifications.Server.CloseReason.DISMISSED);
            dismiss ();
        });

        enter_notify_event.connect (() => {
            close_revealer.reveal_child = true;
            stop_timeout ();
            return Gdk.EVENT_PROPAGATE;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return Gdk.EVENT_STOP;
            }
            close_revealer.reveal_child = false;
            return Gdk.EVENT_PROPAGATE;
        });

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });
    }

    protected void stop_timeout () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }
    }

    protected void start_timeout (uint timeout) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = GLib.Timeout.add (timeout, () => {
            timeout_id = 0;
            closed (Notifications.Server.CloseReason.EXPIRED);
            dismiss ();
            return false;
        });
    }

    public void dismiss () {
        revealer.reveal_child = false;
        GLib.Timeout.add (revealer.transition_duration, () => {
            destroy ();
            return false;
        });
    }
}
