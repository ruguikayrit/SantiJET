import React, { useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { LegalDocumentModal } from "@/components/LegalDocumentModal";
import {
  DATA_SOURCE_LABEL,
  DISCLAIMER_LINES,
  getAppVersion,
  PRIVACY_POLICY,
  TERMS_OF_USE,
} from "@/constants/appInfo";

interface AppFooterProps {
  color: string;
  linkColor: string;
  bottomInset: number;
}

export function AppFooter({ color, linkColor, bottomInset }: AppFooterProps) {
  const [legalDoc, setLegalDoc] = useState<typeof PRIVACY_POLICY | typeof TERMS_OF_USE | null>(
    null,
  );

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
          <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(PRIVACY_POLICY)}>
            <Text style={[styles.link, { color: linkColor }]}>Gizlilik Politikası</Text>
          </TouchableOpacity>
          <Text style={[styles.sep, { color }]}>·</Text>
          <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(TERMS_OF_USE)}>
            <Text style={[styles.link, { color: linkColor }]}>Kullanım Koşulları</Text>
          </TouchableOpacity>
        </View>

        <Text style={[styles.meta, { color }]}>
          Veri: {DATA_SOURCE_LABEL} · v{getAppVersion()}
        </Text>
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
    gap: 8,
    marginTop: 8,
  },
  link: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    textDecorationLine: "underline",
  },
  sep: {
    fontSize: 10,
    fontFamily: "Inter_400Regular",
    opacity: 0.7,
  },
  meta: {
    fontSize: 9,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    opacity: 0.85,
    marginTop: 4,
  },
});
