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
          <View style={styles.linkLeftSlot}>
            <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(PRIVACY_POLICY)}>
              <Text style={[styles.link, styles.linkLeft, { color: linkColor }]}>
                GİZLİLİK POLİTİKASI
              </Text>
            </TouchableOpacity>
          </View>

          <View style={styles.linkCenterSlot}>
            <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(TERMS_OF_USE)}>
              <Text style={[styles.link, styles.linkCenter, { color: linkColor }]}>
                KULLANIM KOŞULLARI
              </Text>
            </TouchableOpacity>
          </View>

          <View style={styles.linkRightSlot}>
            <TouchableOpacity activeOpacity={0.75} onPress={() => setLegalDoc(DATA_SOURCES)}>
              <Text style={[styles.link, styles.linkRight, { color: linkColor }]}>KAYNAK</Text>
            </TouchableOpacity>
          </View>
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
    width: "100%",
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
    width: "100%",
    marginTop: 8,
  },
  linkLeftSlot: {
    flex: 1,
    alignItems: "flex-start",
  },
  linkCenterSlot: {
    flex: 1,
    alignItems: "center",
  },
  linkRightSlot: {
    flex: 1,
    alignItems: "flex-end",
  },
  link: {
    fontSize: 9,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 0.3,
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
    fontSize: 9,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    opacity: 0.85,
    marginTop: 6,
    letterSpacing: 0.2,
  },
});
