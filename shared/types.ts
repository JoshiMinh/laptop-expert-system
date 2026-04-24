export type BudgetLevel = "low" | "medium" | "high";

export type UsageChoice =
  | "office"
  | "coding"
  | "gaming"
  | "design"
  | "content_creation"
  | "ai"
  | "portable";

export interface RecommendRequest {
  budget: BudgetLevel;
  usage: UsageChoice[];
  brand?: string;
  min_battery_hours?: number;
}

export interface Laptop {
  id: number;
  name: string;
  brand: string;
  price: number;
  cpu: string;
  ram: number;
  gpu: string;
  category: string;
  weight_kg?: number | null;
  battery_hours?: number | null;
  has_dedicated_gpu: boolean;
}

export interface LaptopRecommendation extends Laptop {
  score: number;
  fit_reasons: string[];
}

export interface RecommendationResponse {
  recommendations: LaptopRecommendation[];
  explanation: string[];
}
