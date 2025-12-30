using Toybox.WatchUi;
using Toybox.System;

module Affect {

    // Input delegate with view toggle support
    class AffectDelegate extends WatchUi.BehaviorDelegate {
        
        private var view;
        
        function initialize(affectView) {
            BehaviorDelegate.initialize();
            view = affectView;
        }
        
        // Tap to toggle between emotion view and metrics view
        function onSelect() {
            if (view != null) {
                view.toggleView();
            }
            return true;
        }
        
        // Long press to reset/recalibrate
        function onMenu() {
            if (view != null) {
                view.retry();
            }
            return true;
        }
        
        function onBack() {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
    }
}
