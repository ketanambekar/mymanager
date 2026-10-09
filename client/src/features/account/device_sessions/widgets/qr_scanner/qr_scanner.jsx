import { useEffect, useRef } from "react";
import "./qr_scanner.css";

export default function QrScanner({ onScan, onUnavailable }) {
  const videoRef = useRef(null);

  useEffect(() => {
    let active = true;
    let stream;
    let animationFrame;
    let detector;

    async function start() {
      if (!("BarcodeDetector" in window)) {
        onUnavailable("QR scanning is not supported by this browser. Enter the 10-digit code instead.");
        return;
      }
      if (!navigator.mediaDevices?.getUserMedia) {
        onUnavailable("Camera access is unavailable here. Enter the 10-digit code instead.");
        return;
      }
      try {
        detector = new window.BarcodeDetector({ formats: ["qr_code"] });
        stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" }, audio: false });
        if (!active) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
        const detect = async () => {
          if (!active) return;
          if (!videoRef.current || videoRef.current.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
            animationFrame = window.requestAnimationFrame(detect);
            return;
          }
          try {
            const results = await detector.detect(videoRef.current);
            if (active && results.length) {
              onScan(results[0].rawValue);
              return;
            }
          } catch {
            onUnavailable("The camera could not read a QR code. Try manual code entry.");
            return;
          }
          if (active) animationFrame = window.requestAnimationFrame(detect);
        };
        animationFrame = window.requestAnimationFrame(detect);
      } catch (error) {
        if (active) onUnavailable(error.name === "NotAllowedError"
          ? "Camera permission was not granted. You can still enter the code manually."
          : "The camera could not be started. You can still enter the code manually.");
      }
    }

    void start();
    return () => {
      active = false;
      window.cancelAnimationFrame(animationFrame);
      stream?.getTracks().forEach((track) => track.stop());
      if (videoRef.current) videoRef.current.srcObject = null;
    };
  }, [onScan, onUnavailable]);

  return <video aria-label="Camera view for scanning a MyManger sign-in QR code" className="qr-scanner-video" muted playsInline ref={videoRef} />;
}
