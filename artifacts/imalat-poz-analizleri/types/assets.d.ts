declare module "*.json" {
  const value: unknown;
  export default value;
}

declare module "*.png" {
  import { ImageSourcePropType } from "react-native";
  const value: ImageSourcePropType;
  export default value;
}
