import React, { useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { LegalDocumentModal } from "@/components/LegalDocumentModal";
import { SourceModal } from "@/components/SourceModal";
import {
  DISCLAIMER_LINES,
  getAppVersion,
  PRIVACY_POLICY,
  TERMS_OF_USE,
  type LegalDocument,
} from "@/constants/appInfo";

interface AppFooterProps {
  color: string;
  linkColor: string;
  bottomInset: number;
}

type FooterLink =
  | { label: string; kind: "legal"; document: LegalDocument; align: "left" | "center" | "right" }
  | { label: string; kind: "source"; align: "left" | "center" | "right" };

const FOOTER_LINKS: FooterLink[] = [
  { label: "GİZLİLİK POLİTİKASI", kind: "legal", document: PRIVACY_POLICY, align: "left" },
  { label: "KAYNAK", kind: "source", align: "center" },
  { label: "KULLANIM KOŞULLARI", kind: "legal", document: TERMS_OF_USE, align: "right" },
];

export function AppFooter({ color, linkColor, bottomInset }: AppFooterProps) {
  const [legalDoc, setLegalDoc] = useState<LegalDocument | null>(null);
  const [sourceVisible, setSourceVisible] = useState(false);

  function openLink(item: FooterLink) {
    if (item.kind === "source") {
      setSourceVisible(true);
      return;
    }
    setLegalDoc(item.document);
  }

  return (
    <>
      <View
        style={[
          styles.wrap,
          { paddingBottom: bottomInset + 24, paddingTop: 20 },
        ]}
      >
        {DISCLAIMER_LINES.map((line) => (
          <Text key={line} style={[styles.disclaimer, { color }]}>
            {line}
          </Text>
        ))}

        <View style={styles.linkBlock}>
          <View style={styles.linkRow}>
            {FOOTER_LINKS.map((item) => (
              <TouchableOpacity
                key={item.label}
                activeOpacity={0.75}
                style={[
                  styles.linkSlot,
                  item.align === "left" && styles.linkSlotLeft,
                  item.align === "center" && styles.linkSlotCenter,
                  item.align === "right" && styles.linkSlotRight,
                ]}
                onPress={() => openLink(item)}
              >
                <Text
                  style={[
                    styles.link,
                    item.align === "left" && styles.linkLeft,
                    item.align === "center" && styles.linkCenter,
                    item.align === "right" && styles.linkRight,
                    { color: linkColor },
                  ]}
                  numberOfLines={1}
                  adjustsFontSizeToFit
                  minimumFontScale={0.65}
                >
                  {item.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={[styles.version, { color }]}>v{getAppVersion()}</Text>
        </View>
      </View>

      <LegalDocumentModal
        visible={legalDoc != null}
        document={legalDoc}
        onClose={() => setLegalDoc(null)}
      />

      <SourceModal visible={sourceVisible} onClose={() => setSourceVisible(false)} />
    </>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingHorizontal: 12,
    gap: 4,
    alignItems: "center",
    width: "100%",
  },
  disclaimer: {
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    lineHeight: 14,
    textAlign: "center",
  },
  linkBlock: {
    width: "100%",
    marginTop: 8,
    gap: 4,
    alignItems: "center",
  },
  linkRow: {
    flexDirection: "row",
    alignItems: "center",
    width: "100%",
    flexWrap: "nowrap",
  },
  linkSlot: {
    flex: 1,
    minWidth: 0,
    paddingHorizontal: 2,
  },
  linkSlotLeft: {
    alignItems: "flex-start",
  },
  linkSlotCenter: {
    alignItems: "center",
  },
  linkSlotRight: {
    alignItems: "flex-end",
  },
  link: {
    fontSize: 8,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 0.2,
    textDecorationLine: "underline",
  },
  linkLeft: {
    textAlign: "left",
  },
  linkCenter: {
    textAlign: "center",
  },
  linkRight: {
    textAlign: "right",
  },
  version: {
    fontSize: 8,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    opacity: 0.85,
    letterSpacing: 0.2,
  },
});
