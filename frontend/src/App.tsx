import { useEffect, useState } from "react";

import { fetchLaptops, fetchRecommendations } from "./api";
import type { Laptop, BudgetLevel, UsageChoice, RecommendationResponse } from "@shared/types";

const USAGE_OPTIONS: Array<{ value: UsageChoice; label: string; hint: string }> = [
  { value: "office", label: "Office", hint: "Docs, meetings, browsing" },
  { value: "coding", label: "Coding", hint: "Development, IDEs, VMs" },
  { value: "gaming", label: "Gaming", hint: "GPU-heavy games" },
  { value: "design", label: "Design", hint: "Photo, video, illustration" },
  { value: "content_creation", label: "Content", hint: "Editing and publishing" },
  { value: "ai", label: "AI / ML", hint: "Local models and training" },
  { value: "portable", label: "Portable", hint: "Light and long battery" },
];

const BUDGET_OPTIONS: Array<{ value: BudgetLevel; label: string; description: string }> = [
  { value: "low", label: "Low", description: "Best value under a tight budget" },
  { value: "medium", label: "Medium", description: "Balanced performance and cost" },
  { value: "high", label: "High", description: "Premium / workstation range" },
];

export function App() {
  const [budget, setBudget] = useState<BudgetLevel>("medium");
  const [usage, setUsage] = useState<UsageChoice[]>(["coding"]);
  const [brand, setBrand] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [response, setResponse] = useState<RecommendationResponse | null>(null);
  const [catalog, setCatalog] = useState<Laptop[]>([]);

  useEffect(() => {
    fetchLaptops()
      .then(setCatalog)
      .catch(() => {
        setCatalog([]);
      });
  }, []);

  function toggleUsage(option: UsageChoice) {
    setUsage((current) =>
      current.includes(option)
        ? current.filter((item) => item !== option)
        : [...current, option],
    );
  }

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const result = await fetchRecommendations({
        budget,
        usage,
        brand: brand.trim() || undefined,
      });
      setResponse(result);
    } catch (submissionError) {
      setError(submissionError instanceof Error ? submissionError.message : "Failed to get recommendations");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page-shell">
      <div className="ambient ambient-left" />
      <div className="ambient ambient-right" />

      <main className="app-grid">
        <section className="hero-panel">
          <div className="eyebrow">Local rule-based expert system</div>
          <h1>Laptop recommendations with explainable forward chaining.</h1>
          <p className="lede">
            Combine your budget and usage needs, then let the rule engine reason over the local SQLite catalog.
          </p>

          <div className="stats-row">
            <div className="stat-card">
              <span>{catalog.length || 15}</span>
              <p>Seeded laptops</p>
            </div>
            <div className="stat-card">
              <span>25</span>
              <p>Rules loaded</p>
            </div>
            <div className="stat-card">
              <span>100%</span>
              <p>Local execution</p>
            </div>
          </div>

          <form className="control-panel" onSubmit={handleSubmit}>
            <div className="field-group">
              <label htmlFor="brand">Optional brand filter</label>
              <input
                id="brand"
                value={brand}
                onChange={(event) => setBrand(event.target.value)}
                placeholder="e.g. Lenovo or ASUS"
              />
            </div>

            <div className="field-group">
              <label>Budget</label>
              <div className="segmented-control">
                {BUDGET_OPTIONS.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    className={budget === option.value ? "segment active" : "segment"}
                    onClick={() => setBudget(option.value)}
                  >
                    <strong>{option.label}</strong>
                    <span>{option.description}</span>
                  </button>
                ))}
              </div>
            </div>

            <div className="field-group">
              <label>Usage needs</label>
              <div className="usage-grid">
                {USAGE_OPTIONS.map((option) => {
                  const selected = usage.includes(option.value);
                  return (
                    <button
                      key={option.value}
                      type="button"
                      className={selected ? "usage-chip selected" : "usage-chip"}
                      onClick={() => toggleUsage(option.value)}
                    >
                      <strong>{option.label}</strong>
                      <span>{option.hint}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            <button className="submit-button" type="submit" disabled={loading || usage.length === 0}>
              {loading ? "Running inference..." : "Recommend laptops"}
            </button>
            {error ? <div className="error-banner">{error}</div> : null}
          </form>
        </section>

        <section className="results-panel">
          <div className="panel-header">
            <h2>Recommendations</h2>
            <p>Sorted by match score and rule-derived constraints.</p>
          </div>

          {response?.recommendations.length ? (
            <div className="recommendation-list">
              {response.recommendations.map((laptop) => (
                <article key={laptop.id} className="laptop-card">
                  <div className="card-topline">
                    <div>
                      <h3>{laptop.name}</h3>
                      <p>{laptop.brand} · {laptop.category}</p>
                    </div>
                    <div className="score-pill">{laptop.score.toFixed(1)}</div>
                  </div>

                  <dl className="spec-grid">
                    <div>
                      <dt>Price</dt>
                      <dd>${laptop.price}</dd>
                    </div>
                    <div>
                      <dt>RAM</dt>
                      <dd>{laptop.ram}GB</dd>
                    </div>
                    <div>
                      <dt>GPU</dt>
                      <dd>{laptop.gpu}</dd>
                    </div>
                    <div>
                      <dt>Battery</dt>
                      <dd>{laptop.battery_hours ?? "N/A"}h</dd>
                    </div>
                  </dl>

                  <ul className="reason-list">
                    {laptop.fit_reasons.map((reason) => (
                      <li key={reason}>{reason}</li>
                    ))}
                  </ul>
                </article>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              <h3>No recommendation yet</h3>
              <p>Pick a budget and usage mix, then run the engine to see the reasoning trace.</p>
            </div>
          )}

          {response?.explanation.length ? (
            <div className="explanation-panel">
              <div className="panel-header">
                <h2>Explanation</h2>
                <p>Rules fired and the selection rationale.</p>
              </div>
              <ol className="explanation-list">
                {response.explanation.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ol>
            </div>
          ) : null}
        </section>
      </main>
    </div>
  );
}
