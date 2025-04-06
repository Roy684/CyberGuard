import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class TextCaptureService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val text = event?.text?.joinToString(" ")
        // Send text to Flutter via EventChannel or MethodChannel
    }

    override fun onInterrupt() {}
}