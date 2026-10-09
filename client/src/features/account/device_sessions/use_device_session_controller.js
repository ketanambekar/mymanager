import { useCallback, useEffect, useRef, useState } from "react";
import { getApiErrorMessage } from "@/services/api_client.js";
import { decideQrLogin, getDeviceSessions, lookupQrLogin, revokeDeviceSession } from "./device_session_repository.js";
import { parseDeviceQrPayload } from "./device_session_utils.js";

export function useDeviceSessionController(onCurrentDeviceRevoked) {
  const [devices, setDevices] = useState([]);
  const [activeCount, setActiveCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [deviceToRevoke, setDeviceToRevoke] = useState(null);
  const [isRevoking, setIsRevoking] = useState(false);
  const [lookupError, setLookupError] = useState("");
  const [isLookingUp, setIsLookingUp] = useState(false);
  const [approval, setApproval] = useState(null);
  const [decisionState, setDecisionState] = useState("idle");
  const [decisionError, setDecisionError] = useState("");
  const [isDeciding, setIsDeciding] = useState(false);
  const [notice, setNotice] = useState(null);
  const noticeTimer = useRef(null);
  const listPendingRef = useRef(false);
  const revokePendingRef = useRef(false);
  const lookupPendingRef = useRef(false);
  const decisionPendingRef = useRef(false);

  const notify = useCallback((message, tone = "success") => {
    setNotice({ message, tone });
    window.clearTimeout(noticeTimer.current);
    noticeTimer.current = window.setTimeout(() => setNotice(null), 4500);
  }, []);

  const loadDevices = useCallback(async () => {
    if (listPendingRef.current) return;
    listPendingRef.current = true;
    setIsLoading(true);
    setLoadError("");
    try {
      const result = await getDeviceSessions();
      setDevices(result.devices);
      setActiveCount(result.activeCount);
    } catch (error) {
      setLoadError(getApiErrorMessage(error));
    } finally {
      setIsLoading(false);
      listPendingRef.current = false;
    }
  }, []);

  useEffect(() => {
    void loadDevices();
    return () => window.clearTimeout(noticeTimer.current);
  }, [loadDevices]);

  async function confirmRevoke() {
    if (!deviceToRevoke || revokePendingRef.current) return;
    revokePendingRef.current = true;
    setIsRevoking(true);
    try {
      const result = await revokeDeviceSession(deviceToRevoke.id);
      setDeviceToRevoke(null);
      if (result.isCurrent) {
        onCurrentDeviceRevoked();
        return;
      }
      notify(`${deviceToRevoke.deviceName} was signed out.`);
      await loadDevices();
    } catch (error) {
      notify(getApiErrorMessage(error), "error");
    } finally {
      setIsRevoking(false);
      revokePendingRef.current = false;
    }
  }

  const findQrRequest = useCallback(async (code) => {
    if (lookupPendingRef.current) return;
    if (!/^[0-9]{10}$/.test(code)) {
      setLookupError("Enter all 10 digits from the sign-in request.");
      return;
    }
    lookupPendingRef.current = true;
    setIsLookingUp(true);
    setLookupError("");
    setApproval(null);
    setDecisionState("idle");
    setDecisionError("");
    try {
      const request = await lookupQrLogin(code);
      setApproval({ ...request, code });
    } catch (error) {
      setLookupError(getApiErrorMessage(error));
    } finally {
      setIsLookingUp(false);
      lookupPendingRef.current = false;
    }
  }, []);

  const findQrRequestFromPayload = useCallback(async (value) => {
    try {
      const code = parseDeviceQrPayload(value);
      await findQrRequest(code);
    } catch (error) {
      setLookupError(error.message);
    }
  }, [findQrRequest]);

  async function decideRequest(decision) {
    if (!approval || decisionPendingRef.current) return;
    decisionPendingRef.current = true;
    setIsDeciding(true);
    setDecisionError("");
    setDecisionState("pending");
    try {
      const result = await decideQrLogin(approval.challengeId, approval.code, decision);
      setDecisionState(result.status);
      setApproval(null);
      notify(decision === "approve" ? "New device sign-in approved." : "Sign-in request denied.");
    } catch (error) {
      const status = error.response?.status;
      setDecisionState(status === 409 ? "expired" : "error");
      setDecisionError(getApiErrorMessage(error));
    } finally {
      setIsDeciding(false);
      decisionPendingRef.current = false;
    }
  }

  function closeApproval() {
    setApproval(null);
    setDecisionState("idle");
    setDecisionError("");
  }

  return {
    devices, activeCount, isLoading, loadError, loadDevices,
    deviceToRevoke, setDeviceToRevoke, isRevoking, confirmRevoke,
    lookupError, isLookingUp, findQrRequest, findQrRequestFromPayload,
    approval, decisionState, decisionError, isDeciding, decideRequest, closeApproval,
    notice, clearNotice: () => setNotice(null),
  };
}
