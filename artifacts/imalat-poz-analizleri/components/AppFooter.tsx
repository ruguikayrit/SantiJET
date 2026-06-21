import React, { useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { LegalDocumentModal } from "@/components/LegalDocumentModal";
import {
  DATA_SOURCES,
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

const FOOTER_LINKS: { label: string; document: LegalDocument }[] = [
  { label: "GİZLİLİK POLİTİKASI", document: PRIVACY_POLICY },
  { label: "KULLANIM KOŞULLARI", document: TERMS_OF_USE },
  { label: "KAYNAK", document: DATA_SOURCES },
];

export function AppFooter({ color, linkColor, bottomInset }: AppFooterProps) {
  const [legalDoc, setLegalDoc] = useState<LegalDocument | null>(null);

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

        <View style={styles.linkRow}>
          {FOOTER_LINKS.map((item, index) => (
            <View key={item.label} style={styles.linkItem}>
              {index > 0 ? <Text style={[styles.sep, { color }]}> - </Text> : null}
              <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(item.document)}>
                <Text style={[styles.link, { color: linkColor }]}>{item.label}</Text>
              </TouchableOpacity>
            </View>
          ))}
        </View>

        <Text style={[styles.version, { color }]}>v{getAppVersion()}</Text>
      </View>

      <LegalDocumentModal
        visible={legalDoc != null}
        document={legalDoc}
        onClose={() => setLegalDoc(null)}
      />
    </>
  );
}

const styles = StyleSheet.create({
  wrap: {
    paddingHorizontal: 16,
    gap: 4,
    alignItems: "center",
  },
  disclaimer: {
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    lineHeight: 14,
    textAlign: "center",
  },
  linkRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    flexWrap: "wrap",
    marginTop: 8,
  },
  linkItem: {
    flexDirection: "row",
    alignItems: "center",
  },
  link: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 0.3,
    textDecorationLine: "underline",
  },
  sep: {
    fontSize: 9,
    fontFamily: "Inter_400Regular",
    opacity: 0.7,
  },
  version: {
    fontSize: 9,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    opacity: 0.85,
    marginTop: 6,
    letterSpacing: 0.2,
  },
});
