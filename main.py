"""
Prolog Laptop Expert System - Streamlit UI

A Streamlit application that bridges Python and Prolog for intelligent laptop recommendations.
This module handles UI rendering, user input collection, Prolog query execution, and result
presentation with confidence scoring.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Optional, Tuple

import streamlit as st

# Fix Windows asyncio issue on import
try:
    import asyncio
    if hasattr(asyncio, 'WindowsSelectorEventLoopPolicy'):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
except Exception:
    pass

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
    ("Văn phòng", "van_phong"),
    ("Lập trình", "lap_trinh"),
    ("Lập trình iOS", "lap_trinh_ios"),
    ("Đồ họa", "do_hoa"),
    ("Gaming", "gaming"),
    ("AI / Data Science", "ai_data_science"),
]

# UI option mappings for device traits
TRAIT_OPTIONS = [
    ("Mỏng nhẹ", "mong_nhe"),
    ("Pin trâu", "pin_trau"),
    ("Giá rẻ", "gia_re"),
    ("Tầm trung", "tam_trung"),
    ("Màn hình lớn", "man_to"),
    ("GPU rời", "gpu_roi"),
    ("GPU onboard", "gpu_onboard"),
]

BRAND_OPTIONS = ["acer", "asus", "dell", "gigabyte", "hp", "apple"]


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
    if trait in {"mong_nhe", "pin_trau", "gia_re", "tam_trung", "man_to", "gpu_roi", "gpu_onboard"}:
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


def build_query(need: str, budget: int, requirements: list[str], top_k: int) -> str:
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
    return f"tu_van_top_k_giai_thich({need}, {budget}, {extra}, {top_k}, TopK, CanhBao)"


def run_recommendation(need: str, budget: int, requirements: list[str], top_k: int) -> dict[str, Any]:
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
    engine = load_prolog()
    query = build_query(need, budget, requirements, top_k)
    results = list(engine.query(query, maxresult=1))
    
    if not results:
        return {
            "rows": [],
            "warning": "Không có kết quả phù hợp.",
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
    st.markdown("Intelligent laptop recommendations powered by Prolog logic rules and confidence scoring")
    st.divider()

    # ===== Sidebar: Input Form =====
    with st.sidebar:
        st.header("⚙️ Consultation Form")
        
        # Workload selection
        need_label = st.selectbox(
            "🎯 **Nhu cầu**",
            [label for label, _ in NEED_OPTIONS],
            index=4
        )
        need = _label_to_value(NEED_OPTIONS, need_label)

        # Budget input
        budget = st.number_input(
            "💰 **Ngân sách (VND)**",
            min_value=1_000_000,
            max_value=200_000_000,
            value=35_000_000,
            step=500_000,
            help="Set your maximum budget in Vietnamese Dong"
        )

        # Results count slider
        top_k = st.slider(
            "📊 **Số kết quả**",
            min_value=1,
            max_value=10,
            value=5,
            help="Number of recommendations to display"
        )

        # Additional traits
        trait_labels = st.multiselect(
            "✨ **Yêu cầu thêm**",
            [label for label, _ in TRAIT_OPTIONS],
            default=["Mỏng nhẹ"],
            help="Select additional device characteristics"
        )
        traits = [_trait_to_prolog_atom(_label_to_value(TRAIT_OPTIONS, label)) for label in trait_labels]

        # Brand preference
        brand_label = st.selectbox(
            "🏢 **Thương hiệu ưu tiên**",
            ["(không chọn)", *BRAND_OPTIONS],
            index=0
        )
        brand_requirement = None
        if brand_label != "(không chọn)":
            brand_requirement = f"thich_thuong_hieu({_quote_atom(brand_label)})"

        # Submit button
        st.divider()
        submit = st.button("🚀 Chạy tư vấn", type="primary", width='stretch')

    # ===== Main Content: Results Display =====
    requirements = list(traits)
    if brand_requirement:
        requirements.append(brand_requirement)

    if submit:
        with st.spinner("⏳ Querying Prolog advisor..."):
            try:
                result = run_recommendation(need, int(budget), requirements, top_k)
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
                    "Giá (VND)": f"₫{row['price']:,}" if row["price"] else "N/A",
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
                        st.metric("Price", f"₫{row['price']:,}" if row["price"] else "N/A")
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
        st.info("👈 Adjust your consultation parameters in the sidebar and click **Chạy tư vấn** to get recommendations.")


if __name__ == "__main__":
    main()
