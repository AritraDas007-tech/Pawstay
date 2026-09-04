"""
SQLAlchemy ORM models for PawStay database.
Includes Users, Services, Service Images, Packages, Bookings, Reviews, Payments, Notifications, Pets, and OTPs.
"""

from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from .db import Base
import hashlib
import os
import json


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    phone_number = Column(String(20), nullable=True)
    profile_image = Column(Text, nullable=True)
    password_hash = Column(String(255), nullable=True)

    state = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    postal_code = Column(String(20), nullable=False)
    role = Column(String(50), default="User", nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    is_online = Column(Boolean, default=True, nullable=False)
    bio = Column(Text, nullable=True)
    rating = Column(Float, default=5.0, nullable=False)
    reviews_count = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    services = relationship("Service", back_populates="provider", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")

    def set_password(self, password: str):
        salt = os.urandom(16)
        pwd_hash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000)
        self.password_hash = f"{salt.hex()}:{pwd_hash.hex()}"

    def check_password(self, password: str) -> bool:
        if not self.password_hash or ":" not in self.password_hash:
            return False
        try:
            salt_hex, hash_hex = self.password_hash.split(":", 1)
            salt = bytes.fromhex(salt_hex)
            expected_hash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000).hex()
            return expected_hash == hash_hex
        except Exception:
            return False


class OtpCode(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(120), index=True, nullable=False)
    code = Column(String(10), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class Pet(Base):
    __tablename__ = "pets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(120), index=True, nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(50), nullable=False)
    age = Column(Integer, default=1, nullable=False)
    dietary_preferences = Column(Text, nullable=True)
    health_status = Column(Text, nullable=True)
    profile_image = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    price_per_day = Column(Float, default=0.0, nullable=False)
    price_per_hour = Column(Float, default=0.0, nullable=False)
    max_pets = Column(Integer, default=4, nullable=False)
    available_slots = Column(Integer, default=4, nullable=False)
    total_slots = Column(Integer, default=4, nullable=False)
    status = Column(String(20), default="Active", nullable=False, index=True)  # Active, Paused, Deleted

    address = Column(String(255), nullable=True)
    city = Column(String(100), nullable=True, index=True)
    pincode = Column(String(20), nullable=True)
    notes = Column(Text, nullable=True)

    food_included = Column(Boolean, default=True, nullable=False)
    medicine_support = Column(Boolean, default=True, nullable=False)
    pickup_drop = Column(Boolean, default=False, nullable=False)
    outdoor_walks = Column(Boolean, default=True, nullable=False)
    emergency_vet = Column(Boolean, default=True, nullable=False)
    live_availability = Column(Boolean, default=True, nullable=False)
    instant_booking = Column(Boolean, default=True, nullable=False)

    booking_duration = Column(String(50), default="1 Week", nullable=False)
    start_time = Column(String(20), default="08:00", nullable=False)
    end_time = Column(String(20), default="20:00", nullable=False)

    # JSON stored as Text strings
    pets_accepted = Column(Text, default="[\"Dogs\", \"Cats\"]", nullable=False)
    pet_sizes = Column(Text, default="[\"Small\", \"Medium\"]", nullable=False)
    food_types = Column(Text, default="[\"Homemade\", \"Dry Food\"]", nullable=False)
    amenities = Column(Text, default="[\"Air Conditioning\", \"CCTV\", \"Play Area\"]", nullable=False)

    cover_image = Column(Text, nullable=True)
    views = Column(Integer, default=0, nullable=False)
    bookings_count = Column(Integer, default=0, nullable=False)
    rating = Column(Float, default=5.0, nullable=False)
    reviews_count = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    provider = relationship("User", back_populates="services")
    images = relationship("ServiceImage", back_populates="service", cascade="all, delete-orphan")
    packages = relationship("Package", back_populates="service", cascade="all, delete-orphan")
    bookings = relationship("Booking", back_populates="service")
    reviews = relationship("Review", back_populates="service")


class ServiceImage(Base):
    __tablename__ = "service_images"

    id = Column(Integer, primary_key=True, index=True)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), nullable=False, index=True)
    image_url = Column(Text, nullable=False)
    is_cover = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    service = relationship("Service", back_populates="images")


class Package(Base):
    __tablename__ = "packages"

    id = Column(Integer, primary_key=True, index=True)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(120), nullable=False)
    duration = Column(String(50), default="1 Day", nullable=False)
    price = Column(Float, default=0.0, nullable=False)
    features = Column(Text, default="[]", nullable=False)  # JSON text
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    service = relationship("Service", back_populates="packages")


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    booking_code = Column(String(30), unique=True, index=True, nullable=False)
    service_id = Column(Integer, ForeignKey("services.id"), nullable=False, index=True)
    package_id = Column(Integer, ForeignKey("packages.id"), nullable=True)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)

    customer_name = Column(String(100), nullable=False)
    customer_email = Column(String(120), nullable=False)
    customer_phone = Column(String(20), nullable=True)

    pet_name = Column(String(100), nullable=False)
    pet_breed = Column(String(100), nullable=True)
    pet_type = Column(String(50), default="Dog", nullable=False)

    package_title = Column(String(120), nullable=True)
    check_in_date = Column(String(50), nullable=False)
    check_out_date = Column(String(50), nullable=True)
    time_slot = Column(String(100), default="10:00 AM - 06:00 PM", nullable=False)

    status = Column(String(30), default="Pending", nullable=False, index=True)  # Pending, Confirmed, Completed, Cancelled, Rejected
    payment_status = Column(String(30), default="Unpaid", nullable=False)  # Unpaid, Paid, Refunded
    amount = Column(Float, default=0.0, nullable=False)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    service = relationship("Service", back_populates="bookings")
    payment = relationship("Payment", back_populates="booking", uselist=False)
    review = relationship("Review", back_populates="booking", uselist=False)


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    service_id = Column(Integer, ForeignKey("services.id"), nullable=False, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True, unique=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    customer_name = Column(String(100), nullable=False)
    pet_info = Column(String(120), nullable=True)
    rating = Column(Float, default=5.0, nullable=False)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    service = relationship("Service", back_populates="reviews")
    booking = relationship("Booking", back_populates="review")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False, unique=True)
    provider_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    amount = Column(Float, default=0.0, nullable=False)
    status = Column(String(30), default="Completed", nullable=False)  # Pending, Completed, Failed, Refunded
    payment_method = Column(String(50), default="UPI / Card", nullable=False)
    transaction_id = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    booking = relationship("Booking", back_populates="payment")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(150), nullable=False)
    body = Column(Text, nullable=False)
    type = Column(String(50), default="booking", nullable=False)  # booking, payment, review, system
    icon = Column(String(50), default="notifications", nullable=False)
    color_hex = Column(String(20), default="#A55233", nullable=False)
    is_read = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="notifications")
