using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;

// Main Application Entry - must be outside module for Connect IQ to find it
class AffectApp extends Application.AppBase {
    
    private var view;
    
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        view = new Affect.AffectView();
        var delegate = new Affect.AffectDelegate(view);
        return [view, delegate];
    }
}
