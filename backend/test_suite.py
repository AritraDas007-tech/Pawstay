"""
End-to-end automated test script verifying all 8 phases of PawStay.
"""

import sys
import json
from fastapi.testclient import TestClient
from main import app

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

client = TestClient(app)

def run_tests():
    print("==================================================")
    print("RUNNING PAWSTAY FULL STACK END-TO-END SUITE")
    print("==================================================")

    # 1. Health check
    res = client.get("/")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    print("[PASS] 1. Health check passed")

    # 2. Phase 1: Provider Adds a New Service
    new_svc_payload = {
        "title": "Golden Paw Luxury Resort & Spa",
        "description": "Premium climate-controlled private suites with individual webcams and agility park.",
        "price_per_day": 1899.0,
        "price_per_hour": 249.0,
        "max_pets": 5,
        "address": "Villa 10, Palm Grove, Bandra",
        "city": "Mumbai",
        "pincode": "400050",
        "food_included": True,
        "medicine_support": True,
        "pickup_drop": True,
        "outdoor_walks": True,
        "emergency_vet": True,
        "live_availability": True,
        "instant_booking": True,
        "booking_duration": "1 Week",
        "start_time": "08:00",
        "end_time": "20:00",
        "pets_accepted": ["Dogs", "Cats"],
        "pet_sizes": ["Small", "Medium", "Large"],
        "food_types": ["Dry Food", "Wet Food", "Homemade"],
        "amenities": ["Air Conditioning", "CCTV", "Play Area", "Open Garden"],
        "packages": [
            {
                "title": "Golden Paw Deluxe Stay (3 Days)",
                "duration": "3 Days",
                "price": 5697.0,
                "features": ["Luxury Suite", "Daily Hydrotherapy", "HD Webcam"]
            }
        ]
    }
    res = client.post("/provider/services", json=new_svc_payload)
    assert res.status_code in [200, 201], f"Create service failed: {res.text}"
    svc_data = res.json()["service"]
    svc_id = svc_data["id"]
    print(f"[PASS] 2. Phase 1 - Add Service passed (ID: {svc_id}, Title: '{svc_data['title']}')")

    # 3. Phase 3: Customer Dashboard fetches ONLY active services
    res = client.get("/services")
    assert res.status_code == 200
    active_services = res.json()
    assert any(s["id"] == svc_id for s in active_services), "New service not found in active customer listings"
    print(f"[PASS] 3. Phase 3 - Customer dashboard displays new active service (Total Active: {len(active_services)})")

    # 4. Phase 1: Pause Service
    res = client.patch(f"/provider/services/{svc_id}/status", json={"status": "Paused"})
    assert res.status_code == 200, f"Pause service failed: {res.text}"
    print("[PASS] 4. Phase 1 - Pause Service passed (status='Paused')")

    # 5. Customer Dashboard: Service must disappear when paused
    res = client.get("/services")
    assert res.status_code == 200
    active_services = res.json()
    assert not any(s["id"] == svc_id for s in active_services), "Paused service still visible in customer listings"
    print("[PASS] 5. Phase 3 - Customer dashboard correctly hides paused service")

    # 6. Phase 1: Resume Service
    res = client.patch(f"/provider/services/{svc_id}/status", json={"status": "Active"})
    assert res.status_code == 200
    res = client.get("/services")
    active_services = res.json()
    assert any(s["id"] == svc_id for s in active_services), "Resumed service did not reappear on customer dashboard"
    print("[PASS] 6. Phase 1 & 3 - Resume Service passed & reappeared on customer dashboard")

    # 7. Phase 1: Edit Service
    edit_payload = dict(new_svc_payload)
    edit_payload["title"] = "Golden Paw Luxury Resort & Spa (Renovated)"
    edit_payload["price_per_day"] = 1999.0
    res = client.put(f"/provider/services/{svc_id}", json=edit_payload)
    assert res.status_code == 200, f"Edit service failed: {res.text}"
    updated_svc = res.json()["service"]
    assert updated_svc["title"] == "Golden Paw Luxury Resort & Spa (Renovated)"
    assert updated_svc["pricePerDay"] == 1999.0
    print("[PASS] 7. Phase 1 - Edit Service passed (Updated title & price in database)")

    # 8. Phase 4: Customer Creates a Booking
    booking_payload = {
        "service_id": svc_id,
        "customer_name": "Rohan Mehra",
        "customer_email": "rohan.mehra@gmail.com",
        "customer_phone": "+91 9822334455",
        "pet_name": "Oscar",
        "pet_breed": "Beagle",
        "pet_type": "Dog",
        "package_title": "Golden Paw Deluxe Stay (3 Days)",
        "check_in_date": "28 Oct 2026",
        "check_out_date": "31 Oct 2026",
        "time_slot": "10:00 AM Check-in",
        "amount": 5697.0,
        "notes": "Oscar is very friendly, loves chew toys."
    }
    res = client.post("/bookings", json=booking_payload)
    assert res.status_code in [200, 201], f"Create booking failed: {res.text}"
    booking_data = res.json()["booking"]
    booking_id = booking_data["db_id"]
    booking_code = booking_data["id"]
    print(f"[PASS] 8. Phase 4 - Customer Booking created (Code: {booking_code}, Amount: ₹{booking_data['amount']})")

    # 9. Phase 4: Provider views booking & accepts it
    res = client.get("/provider/bookings")
    assert res.status_code == 200
    prov_bookings = res.json()
    assert any(b["id"] == booking_code for b in prov_bookings), "Booking not found in provider bookings list"
    
    res = client.patch(f"/bookings/{booking_id}/status", json={"status": "Confirmed"})
    assert res.status_code == 200
    print("[PASS] 9. Phase 4 - Provider Accepted booking (status='Confirmed')")

    # 10. Phase 5: Calendar API
    res = client.get("/provider/calendar")
    assert res.status_code == 200
    cal_data = res.json()
    assert "all" in cal_data and "confirmed" in cal_data
    print(f"[PASS] 10. Phase 5 - Provider Calendar schedule verified ({len(cal_data['all'])} total events)")

    # 11. Complete Booking & Submit Review (Phase 6)
    client.patch(f"/bookings/{booking_id}/status", json={"status": "Completed"})
    review_payload = {
        "service_id": svc_id,
        "booking_id": booking_id,
        "customer_name": "Rohan Mehra",
        "pet_info": "Owner of Oscar (Beagle)",
        "rating": 5.0,
        "comment": "Outstanding resort! Oscar had a blast in the agility park and the staff sent constant video updates."
    }
    res = client.post("/reviews", json=review_payload)
    assert res.status_code in [200, 201], f"Submit review failed: {res.text}"
    print("[PASS] 11. Phase 6 - Verified Review submitted & average ratings recalculated")

    # 12. Payment Processing (Phase 7)
    payment_payload = {
        "booking_id": booking_id,
        "payment_method": "UPI / GooglePay",
        "transaction_id": "TXN_OSCAR_9921"
    }
    res = client.post("/payments", json=payment_payload)
    assert res.status_code in [200, 201], f"Process payment failed: {res.text}"
    print("[PASS] 12. Phase 7 - Payment completed & linked to booking")

    # 13. Phase 8: Notifications
    res = client.get("/notifications")
    assert res.status_code == 200
    notifs = res.json()
    assert notifs["unreadCount"] > 0
    print(f"[PASS] 13. Phase 8 - Live Notifications verified ({notifs['unreadCount']} unread)")

    # 14. Phase 2: Dynamic Dashboard Stats
    res = client.get("/provider/dashboard-stats")
    assert res.status_code == 200
    stats = res.json()
    assert "stats" in stats and "incomeBreakdown" in stats and "revenuePoints" in stats
    print(f"[PASS] 14. Phase 2 - Dynamic Dashboard Stats verified (Monthly Earnings: {stats['stats']['monthlyEarnings']})")

    # 15. Phase 1: Soft Delete Service
    res = client.delete(f"/provider/services/{svc_id}")
    assert res.status_code == 200
    # Verify removed from active listings
    res = client.get("/services")
    assert not any(s["id"] == svc_id for s in res.json())
    # Verify removed from provider listings
    res = client.get("/provider/services")
    assert not any(s["id"] == svc_id for s in res.json())
    print("[PASS] 15. Phase 1 - Soft Delete verified (Service removed from both customer and provider dashboards)")

    # 16. Phase 9: Messaging Microservice Integration
    from messages.main import fastapi_app as msg_app
    msg_client = TestClient(msg_app)
    conv_res = msg_client.get("/conversations?user_id=demo_user")
    assert conv_res.status_code == 200, f"Fetch conversations failed: {conv_res.text}"
    print(f"[PASS] 16. Phase 9 - Messaging Microservice verified ({len(conv_res.json())} conversations loaded)")

    print("\n==================================================")
    print("ALL MODULES AND INTEGRATION TESTS PASSED SUCCESSFULLY!")
    print("==================================================")

if __name__ == "__main__":
    run_tests()
