from __future__ import annotations

from sqlalchemy import JSON, Boolean, Column, Float, Integer, String
from sqlalchemy.orm import declarative_base


Base = declarative_base()


class Laptop(Base):
    __tablename__ = "laptops"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    brand = Column(String(100), nullable=False)
    price = Column(Integer, nullable=False)
    cpu = Column(String(200), nullable=False)
    ram = Column(Integer, nullable=False)
    gpu = Column(String(200), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    weight_kg = Column(Float, nullable=True)
    battery_hours = Column(Float, nullable=True)
    has_dedicated_gpu = Column(Boolean, nullable=False, default=False)


class Rule(Base):
    __tablename__ = "rules"

    id = Column(String(32), primary_key=True)
    conditions = Column(JSON, nullable=False)
    conclusions = Column(JSON, nullable=False)
    priority = Column(Integer, nullable=False, default=0)
