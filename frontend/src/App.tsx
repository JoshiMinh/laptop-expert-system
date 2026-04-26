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
  const [brands, setBrands] = useState<string[]>([]);
  const [brandQuery, setBrandQuery] = useState("");
  const [isBrandMenuOpen, setIsBrandMenuOpen] = useState(false);
  const [brandActiveIndex, setBrandActiveIndex] = useState(0);
  const [catalogError, setCatalogError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [response, setResponse] = useState<RecommendationResponse | null>(null);
  const [catalog, setCatalog] = useState<Laptop[]>([]);

  useEffect(() => {
    fetchLaptops()
      .then((items) => {
        setCatalog(items);
        setCatalogError(null);
      })
      .catch(() => {
        setCatalog([]);
        setCatalogError("Catalog could not be loaded. Make sure API is running on port 8000.");
      });
  }, []);

  function toggleUsage(option: UsageChoice) {
    setUsage((current) =>
      current.includes(option)
        ? current.filter((item) => item !== option)
        : [...current, option],
    );
  }

  const availableBrands = Array.from(new Set(catalog.map((item) => item.brand))).sort((left, right) =>
    left.localeCompare(right),
  );

  const brandSuggestions = availableBrands
    .filter((brand) => {
      const query = brandQuery.trim().toLowerCase();
      const matchesQuery = query.length === 0 || brand.toLowerCase().includes(query);
      const isAlreadySelected = brands.some((selected) => selected.toLowerCase() === brand.toLowerCase());
      return matchesQuery && !isAlreadySelected;
    })
    .slice(0, 8);

  function addBrand(brandName: string) {
    const normalized = brandName.trim();
    if (!normalized) {
      return;
    }

    const exactMatch = availableBrands.find((brand) => brand.toLowerCase() === normalized.toLowerCase());
    const fuzzyMatch = availableBrands.find((brand) => brand.toLowerCase().includes(normalized.toLowerCase()));
    const nextBrand = exactMatch ?? fuzzyMatch ?? normalized;

    if (!brands.some((item) => item.toLowerCase() === nextBrand.toLowerCase())) {
      setBrands((current) => [...current, nextBrand]);
    }

    setBrandQuery("");
    setBrandActiveIndex(0);
  }

  function removeBrand(brandName: string) {
    setBrands((current) => current.filter((item) => item !== brandName));
  }

  function handleBrandKeyDown(event: React.KeyboardEvent<HTMLInputElement>) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      if (brandSuggestions.length > 0) {
        setIsBrandMenuOpen(true);
        setBrandActiveIndex((current) => Math.min(current + 1, brandSuggestions.length - 1));
      }
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      if (brandSuggestions.length > 0) {
        setIsBrandMenuOpen(true);
        setBrandActiveIndex((current) => Math.max(current - 1, 0));
      }
      return;
    }

    if (event.key === "Enter") {
      event.preventDefault();
      if (isBrandMenuOpen && brandSuggestions[brandActiveIndex]) {
        addBrand(brandSuggestions[brandActiveIndex]);
      } else {
        addBrand(brandQuery);
      }
      return;
    }

    if (event.key === "Escape") {
      setIsBrandMenuOpen(false);
      return;
    }

    if (event.key === "Backspace" && brandQuery.length === 0 && brands.length > 0) {
      setBrands((current) => current.slice(0, -1));
    }
  }

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const result = await fetchRecommendations({
        budget,
        usage,
        brands: brands.length > 0 ? brands : undefined,
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
          <h1>Find the right laptop with transparent rule-based reasoning.</h1>
          <p className="lede">
            Combine your budget and usage needs, then let the rule engine reason over the local SQLite catalog.
          </p>
          {catalogError ? <p className="catalog-warning">{catalogError}</p> : null}

          <div className="stats-row">
            <div className="stat-card">
              <span>{catalog.length}</span>
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
              <label htmlFor="brand-input">Brand filter (optional)</label>
              <div className="brand-combobox">
                <div className="brand-input-wrapper">
                  <div className="brand-chips">
                    {brands.map((brandName) => (
                      <span key={brandName} className="brand-chip">
                        {brandName}
                        <button
                          type="button"
                          className="chip-remove"
                          onClick={() => removeBrand(brandName)}
                          aria-label={`Remove ${brandName}`}
                        >
                          ✕
                        </button>
                      </span>
                    ))}
                    <input
                      id="brand-input"
                      type="text"
                      value={brandQuery}
                      onFocus={() => setIsBrandMenuOpen(true)}
                      onBlur={() => {
                        window.setTimeout(() => setIsBrandMenuOpen(false), 120);
                      }}
                      onChange={(event) => {
                        setBrandQuery(event.target.value);
                        setIsBrandMenuOpen(true);
                        setBrandActiveIndex(0);
                      }}
                      onKeyDown={handleBrandKeyDown}
                      placeholder={brands.length === 0 ? "Type to search brands" : "Add another brand..."}
                      className="brand-text-input"
                      autoComplete="off"
                    />
                  </div>
                </div>
                {isBrandMenuOpen ? (
                  <div className="brand-dropdown" role="listbox" aria-label="Brand suggestions">
                    {brandSuggestions.length > 0 ? (
                      brandSuggestions.map((brandName, index) => (
                        <button
                          key={brandName}
                          type="button"
                          className={index === brandActiveIndex ? "brand-option active" : "brand-option"}
                          onMouseDown={(event) => {
                            event.preventDefault();
                            addBrand(brandName);
                          }}
                          onMouseEnter={() => setBrandActiveIndex(index)}
                        >
                          <strong>{brandName}</strong>
                          <span>{catalog.filter((item) => item.brand === brandName).length} models</span>
                        </button>
                      ))
                    ) : (
                      <div className="brand-empty">No matching brands found.</div>
                    )}
                  </div>
                ) : null}
              </div>
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
