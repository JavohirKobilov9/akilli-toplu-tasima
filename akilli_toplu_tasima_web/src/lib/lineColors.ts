// Mobil uygulamadaki (harita.dart) hat renkleriyle aynı palet: BRT01 - BRT26.
export const LINE_COLORS: Record<string, string> = {
  BRT01: "#E53935", BRT02: "#1E88E5", BRT03: "#43A047", BRT04: "#FB8C00", BRT05: "#8E24AA",
  BRT06: "#00ACC1", BRT07: "#D81B60", BRT08: "#7CB342", BRT09: "#5E35B1", BRT10: "#F4511E",
  BRT11: "#00897B", BRT12: "#3949AB", BRT13: "#AFB42B", BRT14: "#6D4C41", BRT15: "#039BE5",
  BRT16: "#F9A825", BRT17: "#AD1457", BRT18: "#2E7D32", BRT19: "#546E7A", BRT20: "#0D47A1",
  BRT21: "#9E9D24", BRT22: "#00695C", BRT23: "#6A1B9A", BRT24: "#FF8A80", BRT25: "#9575CD",
  BRT26: "#A1887F",
};

// Hat bilinmiyorsa nötr gri.
export const lineColor = (code?: string | null) => (code && LINE_COLORS[code.toUpperCase()]) || "#607D8B";
