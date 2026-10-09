import { useEffect, useState } from "react";
import QRCode from "qrcode";
import "./qr_code.css";

export default function QrCode({ value, label }) {
  const [image, setImage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    setImage("");
    setError("");
    QRCode.toDataURL(value, { errorCorrectionLevel: "M", margin: 2, width: 220 })
      .then((dataUrl) => { if (active) setImage(dataUrl); })
      .catch((generationError) => {
        if (active) setError(generationError.message || "The QR code could not be displayed.");
      });
    return () => { active = false; };
  }, [value]);

  if (error) return <p className="qr-code-error" role="alert">{error}</p>;
  if (!image) return <span className="qr-code-placeholder" role="status">Preparing QR code...</span>;
  return <img alt={label} className="qr-code-image" src={image} />;
}
