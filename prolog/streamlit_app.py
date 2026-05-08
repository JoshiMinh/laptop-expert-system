from __future__ import annotations

from pathlib import Path
from typing import Any, Optional, Tuple

import streamlit as st

try:
    from pyswip import Prolog
except ImportError as exc:  # pragma: no cover - dependency bootstrap path
    raise SystemExit(
        "Missing dependency. Install requirements with: pip install -r requirements.txt"
    ) from exc


APP_DIR = Path(__file__).resolve().parent
ADVISOR_PATH = APP_DIR / "advisor.pl"

NEED_OPTIONS = [
    ("Văn phòng", "van_phong"),
    ("Lập trình", "lap_trinh"),
    ("Lập trình iOS", "lap_trinh_ios"),
    ("Đồ họa", "do_hoa"),
    ("Gaming", "gaming"),
    ("AI / Data Science", "ai_data_science"),
]

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


def _label_to_value(options: list[tuple[str, str]], label: str) -> str:
    for option_label, option_value in options:
        if option_label == label:
            return option_value
    return label


def _quote_atom(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def _trait_to_prolog_atom(trait: str) -> str:
    if trait in {"mong_nhe", "pin_trau", "gia_re", "tam_trung", "man_to", "gpu_roi", "gpu_onboard"}:
        return trait
    return trait


def _strip_outer_quotes(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1]
    return value


def _normalize_warning(value: Any) -> str:
    if isinstance(value, list) and len(value) > 0:
        value = value[0]
    warning = _strip_outer_quotes(str(value).strip())
    if warning in {"none", "[]", "", "null"}:
        return ""
    return warning


def _parse_compound_tuple(text: str) -> Optional[Tuple[str, str, str]]:
    """Parse a compound term like -(-(0.8, Name), 25000000) or (0.8, Name, 25000000) or 0.8-Name-25000000."""
    text = text.strip()
    
    # Handle nested dash format: -(-(CF, Name), Price)
    if text.startswith("-(") and text.count("(") >= 2:
        # Extract the inner structure: -(CF, Name)
        # Find matching parenthesis for first -(
        outer_inner = text[2:-1]  # Remove "- (" and final ")"
        
        # Split by the outermost comma that separates inner and price
        # Working backwards to find price
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
            
            # Parse inner part: -(CF, Name) or just (CF, Name)
            if inner_part.startswith("-(") and inner_part.endswith(")"):
                inner_inner = inner_part[2:-1]
            elif inner_part.startswith("(") and inner_part.endswith(")"):
                inner_inner = inner_part[1:-1]
            else:
                inner_inner = inner_part
            
            # Split CF and Name
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
        # Be careful with dashes in names - split from right with limits
        parts = text.rsplit("-", 1)
        if len(parts) == 2 and parts[1].replace(".", "").isdigit():
            price = parts[1]
            remainder = parts[0]
            # Find the confidence (should be first number followed by dash)
            cf_end = remainder.find("-")
            if cf_end > 0:
                cf = remainder[:cf_end]
                name = remainder[cf_end+1:]
                if cf.replace(".", "").isdigit():
                    return (cf.strip(), name.strip().strip("'\" "), price.strip())
    
    return None


def _parse_row_text(text: Any) -> dict[str, Any]:
    """Parse a single row from Prolog output."""
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


@st.cache_resource
def load_prolog() -> Prolog:
    if not ADVISOR_PATH.exists():
        raise FileNotFoundError(f"Missing Prolog advisor file: {ADVISOR_PATH}")

    engine = Prolog()
    engine.consult(str(ADVISOR_PATH))
    return engine


def build_query(need: str, budget: int, requirements: list[str], top_k: int) -> str:
    extra = "[" + ", ".join(requirements) + "]" if requirements else "[]"
    return f"tu_van_top_k_giai_thich({need}, {budget}, {extra}, {top_k}, TopK, CanhBao)"


def run_recommendation(need: str, budget: int, requirements: list[str], top_k: int) -> dict[str, Any]:
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


def main() -> None:
    st.set_page_config(page_title="Prolog Laptop Demo", page_icon="💡", layout="wide")

    st.title("Prolog Laptop Expert Demo")
    st.write(
        "Standalone Streamlit demo for the Prolog advisor. The UI queries the Prolog rules in this folder through pyswip."
    )

    with st.sidebar:
        st.header("Consultation")

        need_label = st.selectbox("Nhu cầu", [label for label, _ in NEED_OPTIONS], index=4)
        need = _label_to_value(NEED_OPTIONS, need_label)

        budget = st.number_input(
            "Ngân sách (VND)",
            min_value=1_000_000,
            max_value=200_000_000,
            value=35_000_000,
            step=500_000,
        )

        top_k = st.slider("Số kết quả", min_value=1, max_value=10, value=5)

        trait_labels = st.multiselect(
            "Yêu cầu thêm",
            [label for label, _ in TRAIT_OPTIONS],
            default=["Mỏng nhẹ"],
        )
        traits = [_trait_to_prolog_atom(_label_to_value(TRAIT_OPTIONS, label)) for label in trait_labels]

        brand_label = st.selectbox("Thương hiệu ưu tiên", ["(không chọn)", *BRAND_OPTIONS], index=0)
        if brand_label == "(không chọn)":
            brand_requirement = None
        else:
            brand_requirement = f"thich_thuong_hieu({_quote_atom(brand_label)})"

        submit = st.button("Chạy tư vấn", type="primary", use_container_width=True)

    requirements = list(traits)
    if brand_requirement:
        requirements.append(brand_requirement)

    if submit:
        try:
            result = run_recommendation(need, int(budget), requirements, top_k)
        except Exception as exc:  # pragma: no cover - runtime integration guard
            st.error(f"Không chạy được Prolog advisor: {exc}")
            st.stop()

        st.subheader("Kết quả")

        if result["warning"]:
            st.warning(result["warning"])

        if not result["rows"]:
            st.info("Không có laptop nào khớp toàn bộ tiêu chí.")
        else:
            table_rows = []
            for index, row in enumerate(result["rows"], start=1):
                table_rows.append(
                    {
                        "#": index,
                        "Laptop": row["name"],
                        "Giá": row["price"],
                        "CF": row["confidence"],
                    }
                )

            st.dataframe(table_rows, use_container_width=True, hide_index=True)

            for index, row in enumerate(result["rows"], start=1):
                with st.expander(f"#{index} {row['name']}"):
                    st.write(f"**Giá:** {row['price']}")
                    st.write(f"**Độ tin cậy:** {row['confidence']}")

        with st.expander("Raw Prolog query"):
            st.code(result["query"], language="prolog")
    else:
        st.info("Chọn tiêu chí bên trái và nhấn **Chạy tư vấn** để gọi Prolog.")


if __name__ == "__main__":
    main()
