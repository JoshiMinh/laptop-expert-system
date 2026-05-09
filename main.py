"""
Prolog Laptop Expert System - Streamlit UI

A Streamlit application that bridges Python and Prolog for intelligent laptop recommendations.
This module handles UI rendering, user input collection, Prolog query execution, and result
presentation with confidence scoring.
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path
from typing import Any, Optional, Tuple

if sys.platform == "win32" and hasattr(asyncio, "WindowsSelectorEventLoopPolicy"):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

import streamlit as st

try:
    from pyswip import Prolog
except ImportError as exc:  # pragma: no cover - dependency bootstrap path
    raise SystemExit(
        "Missing dependency. Install requirements with: pip install -r requirements.txt"
    ) from exc


APP_DIR = Path(__file__).resolve().parent
ADVISOR_PATH = APP_DIR / "laptop_advisor.pl"

# UI option mappings for workload types
NEED_OPTIONS = [
    ("Office", "office"),
    ("Programming", "programming"),
    ("iOS Development", "ios_development"),
    ("Graphics / Design", "graphics"),
    ("Gaming", "gaming"),
    ("AI / Data Science", "ai_data_science"),
]

# UI option mappings for device traits
TRAIT_OPTIONS = [
    ("Lightweight", "lightweight"),
    ("Long battery life", "long_battery_life"),
    ("Budget-friendly", "budget_friendly"),
    ("Mid-range", "mid_range"),
    ("Large display", "large_display"),
    ("Discrete GPU", "discrete_gpu"),
    ("Integrated GPU", "integrated_gpu"),
]

BRAND_OPTIONS = ["acer", "asus", "dell", "gigabyte", "hp", "apple"]
NO_BRAND_LABEL = "No preference"
MIN_BUDGET = 1_000_000
MAX_BUDGET = 200_000_000
DEFAULT_BUDGET = 35_000_000
MAX_TOP_K = 10


# ==================== Utility Functions ====================

def _label_to_value(options: list[tuple[str, str]], label: str) -> str:
    """Convert a display label to its corresponding Prolog atom value.
    
    Args:
        options: List of (display_label, prolog_value) tuples
        label: The display label to look up
        
    Returns:
        Corresponding Prolog atom value, or the label itself if not found
    """
    for option_label, option_value in options:
        if option_label == label:
            return option_value
    return label


def _quote_atom(value: str) -> str:
    """Escape and quote a string for safe Prolog atom insertion.
    
    Args:
        value: String to quote
        
    Returns:
        Properly escaped quoted string suitable for Prolog
    """
    escaped = value.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def _trait_to_prolog_atom(trait: str) -> str:
    """Validate and convert a trait string to a Prolog atom.
    
    Args:
        trait: Trait identifier string
        
    Returns:
        Valid Prolog atom representation
    """
    if trait in {"lightweight", "long_battery_life", "budget_friendly", "mid_range", "large_display", "discrete_gpu", "integrated_gpu"}:
        return trait
    return trait


def _strip_outer_quotes(value: str) -> str:
    """Remove outer quotes from a string if present.
    
    Args:
        value: String possibly wrapped in quotes
        
    Returns:
        String with outer quotes removed
    """
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1]
    return value


def _normalize_warning(value: Any) -> str:
    """Convert Prolog warning output to a user-friendly string.
    
    Args:
        value: Raw Prolog warning output (may be list, string, or other type)
        
    Returns:
        Normalized warning string, or empty string if no warning
    """
    if isinstance(value, list) and len(value) > 0:
        value = value[0]
    warning = _strip_outer_quotes(str(value).strip())
    if warning in {"none", "[]", "", "null"}:
        return ""
    return warning


def _format_currency(value: Optional[int]) -> str:
    if value is None:
        return "N/A"
    return f"VND {value:,}"


def _validate_inputs(need: str, min_budget: int, max_budget: int, requirements: list[str], top_k: int) -> None:
    valid_needs = {option_value for _, option_value in NEED_OPTIONS}
    valid_traits = {option_value for _, option_value in TRAIT_OPTIONS}

    if need not in valid_needs:
        raise ValueError(f"Invalid workload type: {need}")
    if not (MIN_BUDGET <= min_budget <= MAX_BUDGET) or not (MIN_BUDGET <= max_budget <= MAX_BUDGET):
        raise ValueError(f"Budget values must be between VND {MIN_BUDGET:,} and VND {MAX_BUDGET:,}")
    if min_budget > max_budget:
        raise ValueError("Minimum budget cannot be greater than maximum budget")
    if not (1 <= top_k <= MAX_TOP_K):
        raise ValueError(f"Top-K must be between 1 and {MAX_TOP_K}")

    for requirement in requirements:
        if requirement.startswith("preferred_brand("):
            continue
        if requirement not in valid_traits:
            raise ValueError(f"Invalid requirement atom: {requirement}")

# ==================== Result Parsing Functions ====================

def _parse_compound_tuple(text: str) -> Optional[Tuple[str, str, str]]:
    """Parse Prolog compound term output into (confidence, name, price) tuple.
    
    Handles multiple Prolog output formats:
    - Nested dash format: -(-(0.8, Name), 25000000)
    - Tuple format: (0.8, Name, 25000000)
    - Dash-separated: 0.8-Name-25000000
    
    Args:
        text: Raw Prolog output string
        
    Returns:
        Tuple of (confidence_str, name_str, price_str) or None if parsing fails
    """
    text = text.strip()
    
    # Handle nested dash format: -(-(CF, Name), Price)
    if text.startswith("-(") and text.count("(") >= 2:
        outer_inner = text[2:-1]  # Remove "- (" and final ")"
        
        # Find the outermost comma separating inner part from price
        depth = 0
        split_pos = -1
        for i in range(len(outer_inner) - 1, -1, -1):
            if outer_inner[i] == ')':
                depth += 1
            elif outer_inner[i] == '(':
                depth -= 1
            elif outer_inner[i] == ',' and depth == 0:
                split_pos = i
                break
        
        if split_pos > 0:
            inner_part = outer_inner[:split_pos].strip()
            price = outer_inner[split_pos+1:].strip()
            
            # Parse inner part: -(CF, Name) or (CF, Name)
            if inner_part.startswith("-(") and inner_part.endswith(")"):
                inner_inner = inner_part[2:-1]
            elif inner_part.startswith("(") and inner_part.endswith(")"):
                inner_inner = inner_part[1:-1]
            else:
                inner_inner = inner_part
            
            # Split confidence and name by depth-aware comma
            depth = 0
            for i, char in enumerate(inner_inner):
                if char in "([":
                    depth += 1
                elif char in ")]":
                    depth -= 1
                elif char == "," and depth == 0:
                    cf = inner_inner[:i].strip()
                    name = inner_inner[i+1:].strip()
                    return (cf.strip("'\" "), name.strip("'\" "), price.strip("'\" "))
    
    # Handle tuple format (CF, Name, Price)
    if text.startswith("(") and text.endswith(")"):
        inner = text[1:-1]
        parts = []
        current = ""
        depth = 0
        for char in inner:
            if char in "([":
                depth += 1
            elif char in ")]":
                depth -= 1
            elif char == "," and depth == 0:
                parts.append(current.strip())
                current = ""
                continue
            current += char
        if current:
            parts.append(current.strip())
        
        if len(parts) >= 3:
            return (parts[0].strip("'\" "), parts[1].strip("'\" "), parts[2].strip("'\" "))
    
    # Handle dash format CF-Name-Price
    if "-" in text and not text.startswith("("):
        parts = text.rsplit("-", 1)
        if len(parts) == 2 and parts[1].replace(".", "").isdigit():
            price = parts[1]
            remainder = parts[0]
            # Extract confidence (first numeric value before dash)
            cf_end = remainder.find("-")
            if cf_end > 0:
                cf = remainder[:cf_end]
                name = remainder[cf_end+1:]
                if cf.replace(".", "").isdigit():
                    return (cf.strip(), name.strip().strip("'\" "), price.strip())
    
    return None


def _parse_row_text(text: Any) -> dict[str, Any]:
    """Parse a single recommendation row from Prolog output.
    
    Extracts structured data from raw Prolog query result and converts types.
    
    Args:
        text: Raw Prolog output (any type)
        
    Returns:
        Dictionary with keys: 'confidence' (float|None), 'name' (str), 
                             'price' (int|None), 'raw' (str)
    """
    text_str = str(text).strip()
    parsed = _parse_compound_tuple(text_str)
    
    if parsed:
        cf_str, name_str, price_str = parsed
        try:
            confidence = float(cf_str)
        except (ValueError, TypeError):
            confidence = None
        
        try:
            price = int(float(price_str))
        except (ValueError, TypeError):
            price = None
        
        return {
            "confidence": confidence,
            "name": _strip_outer_quotes(name_str),
            "price": price,
            "raw": text_str,
        }
    
    return {
        "confidence": None,
        "name": text_str,
        "price": None,
        "raw": text_str,
    }

# ==================== Prolog Engine & Query Functions ====================

@st.cache_resource
def load_prolog() -> Prolog:
    """Load and initialize the Prolog engine with the advisor rules."""
    if not ADVISOR_PATH.exists():
        raise FileNotFoundError(f"Missing Prolog advisor file: {ADVISOR_PATH}")

    engine = Prolog()
    engine.consult(str(ADVISOR_PATH))
    return engine


def build_query(need: str, min_budget: int, max_budget: int, requirements: list[str], top_k: int) -> str:
    """Construct a Prolog query for laptop recommendations.
    
    Args:
        need: Workload type (Prolog atom)
        budget: Maximum budget in VND
        requirements: List of trait/preference atoms
        top_k: Number of results to return
        
    Returns:
        Formatted Prolog query string
    """
    extra = "[" + ", ".join(requirements) + "]" if requirements else "[]"
    # Use the Prolog range-aware wrapper (min/max budget)
    return f"recommend_top_k_range({need}, {min_budget}, {max_budget}, {extra}, {top_k}, TopK, Warning)"


def run_recommendation(need: str, min_budget: int, max_budget: int, requirements: list[str], top_k: int) -> dict[str, Any]:
    """Execute Prolog recommendation query and process results.
    
    Args:
        need: Workload type
        budget: Maximum budget in VND
        requirements: List of trait preferences
        top_k: Number of results to return
        
    Returns:
        Dictionary containing:
        - 'rows': List of parsed recommendation dictionaries
        - 'warning': Warning message from Prolog (if any)
        - 'query': The executed Prolog query (for debugging)
    """
    _validate_inputs(need, min_budget, max_budget, requirements, top_k)

    engine = load_prolog()
    query = build_query(need, min_budget, max_budget, requirements, top_k)
    results = list(engine.query(query, maxresult=1))
    
    if not results:
        return {
            "rows": [],
            "warning": "No matching laptops were found.",
            "query": query,
        }

    result = results[0]
    topk_list = result.get("TopK", [])
    rows = []
    if topk_list:
        for item in topk_list:
            rows.append(_parse_row_text(item))

    return {
        "rows": rows,
        "warning": _normalize_warning(result.get("CanhBao", [])),
        "query": query,
    }

# ==================== Main UI ====================

def main() -> None:
    """Render the Streamlit application interface and handle user interactions."""
    st.set_page_config(
        page_title="Prolog Laptop Advisor",
        page_icon="💼",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    st.markdown("""
        <style>
        .recommendation-row { margin-bottom: 1rem; }
        .confidence-high { color: #28a745; font-weight: bold; }
        .confidence-low { color: #dc3545; }
        </style>
    """, unsafe_allow_html=True)

    st.title("💼 Prolog Laptop Advisor")
    st.markdown("Intelligent laptop recommendations powered by Prolog logic rules and confidence scoring.")
    st.divider()

    # ===== Sidebar: Input Form =====
    with st.sidebar:
        st.header("⚙️ Recommendation Form")
        
        # Workload selection
        need_label = st.selectbox(
            "🎯 **Workload**",
            [label for label, _ in NEED_OPTIONS],
            index=4
        )
        need = _label_to_value(NEED_OPTIONS, need_label)

        # Budget range inputs (min / max)
        col_min, col_max = st.columns(2)
        with col_min:
            min_budget = st.number_input(
                "💰 Min budget (VND)",
                min_value=MIN_BUDGET,
                max_value=MAX_BUDGET,
                value=MIN_BUDGET,
                step=500_000,
                help="Minimum budget in VND."
            )
        with col_max:
            max_budget = st.number_input(
                "💰 Max budget (VND)",
                min_value=MIN_BUDGET,
                max_value=MAX_BUDGET,
                value=DEFAULT_BUDGET,
                step=500_000,
                help="Maximum budget in VND."
            )

        # Results count slider
        top_k = st.slider(
            "📊 **Number of results**",
            min_value=1,
            max_value=MAX_TOP_K,
            value=5,
            help="Number of recommendations to display."
        )

        # Additional traits
        trait_labels = st.multiselect(
            "✨ **Additional preferences**",
            [label for label, _ in TRAIT_OPTIONS],
            default=["Lightweight"],
            help="Select additional device characteristics."
        )
        traits = [_trait_to_prolog_atom(_label_to_value(TRAIT_OPTIONS, label)) for label in trait_labels]

        # Brand preference
        brand_label = st.selectbox(
            "🏢 **Preferred brand**",
            [NO_BRAND_LABEL, *BRAND_OPTIONS],
            index=0
        )
        brand_requirement = None
        if brand_label != NO_BRAND_LABEL:
            brand_requirement = f"preferred_brand({_quote_atom(brand_label)})"

        # Submit button
        st.divider()
        submit = st.button("🚀 Run recommendation", type="primary", width='stretch')

    # ===== Main Content: Results Display =====
    requirements = list(traits)
    if brand_requirement:
        requirements.append(brand_requirement)

    if submit:
        with st.spinner("⏳ Querying Prolog advisor..."):
            try:
                result = run_recommendation(need, int(min_budget), int(max_budget), requirements, top_k)
            except ValueError as exc:
                st.error(f"❌ {exc}")
                st.stop()
            except Exception as exc:  # pragma: no cover - runtime integration guard
                st.error(f"❌ Prolog execution failed: {exc}")
                st.stop()

        st.subheader("📋 Recommendations")

        # Display warning if present
        if result["warning"]:
            st.warning(f"⚠️ {result['warning']}")

        # Show "no results" message or results
        if not result["rows"]:
            st.info("😞 No laptops match all your criteria. Try adjusting your preferences.")
        else:
            # Create summary table
            table_rows = []
            for index, row in enumerate(result["rows"], start=1):
                confidence_pct = f"{row['confidence']*100:.0f}%" if row["confidence"] else "N/A"
                table_rows.append({
                    "#": index,
                    "Laptop": row["name"],
                    "Price": _format_currency(row["price"]),
                    "Confidence": confidence_pct,
                })

            st.dataframe(table_rows, width='stretch', hide_index=True)

            # Expandable detail sections for each recommendation
            st.subheader("📄 Details")
            cols = st.columns(1)
            for index, row in enumerate(result["rows"], start=1):
                confidence_pct = f"{row['confidence']*100:.0f}%" if row["confidence"] else "N/A"
                with st.expander(f"**#{index}** {row['name']} — {confidence_pct}"):
                    col1, col2 = st.columns(2)
                    with col1:
                        st.metric("Price", _format_currency(row["price"]))
                    with col2:
                        st.metric("Confidence", confidence_pct)
                    if row["raw"]:
                        st.caption(f"*Raw: {row['raw']}*")

        # Debug section: Show raw Prolog query
        with st.expander("🔍 Debug: Raw Prolog Query"):
            st.code(result["query"], language="prolog")
            st.caption("Use this to verify how your inputs were translated to Prolog.")
    else:
        # Initial state message
        st.info("👈 Adjust the settings in the sidebar and click **Run recommendation** to get recommendations.")


if __name__ == "__main__":
    main()
