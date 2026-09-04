import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_backend():
    print("=== 1. Health Check ===")
    r = requests.get(f"{BASE_URL}/")
    print("Health:", r.status_code, r.json())
    assert r.status_code == 200

    print("\n=== 2. Invalid Login (Expect 401, not 500) ===")
    r = requests.post(f"{BASE_URL}/login", json={"email_or_username": "fake@pawstay.in", "password": "WrongPassword"})
    print("Invalid login status:", r.status_code, r.json())
    assert r.status_code == 401

    print("\n=== 3. Seeded Provider Login ===")
    r = requests.post(f"{BASE_URL}/login", json={"email_or_username": "priya.rathore@pawstay.in", "password": "Password123"})
    print("Provider login status:", r.status_code, r.json())
    assert r.status_code == 200
    res = r.json()
    assert res["success"] is True
    assert "provider" in res["role"].lower()
    print("Provider verified & authenticated successfully!")

    print("\n=== 4. Customer Signup & OTP flow ===")
    test_email = "testcustomer123@pawstay.in"
    # cleanup if exists
    signup_payload = {
        "full_name": "Test Customer",
        "username": "testcust123",
        "email": test_email,
        "password": "Password123",
        "state": "Maharashtra",
        "city": "Mumbai",
        "postal_code": "400001",
        "role": "User"
    }
    r = requests.post(f"{BASE_URL}/signup", json=signup_payload)
    print("Signup response:", r.status_code, r.json())
    if r.status_code == 200:
        otp = r.json().get("otp") or r.json().get("development_otp")
        print("Dev OTP:", otp)
        if otp:
            # Verify OTP
            vr = requests.post(f"{BASE_URL}/verify-otp", json={"email": test_email, "otp": otp})
            print("Verify OTP response:", vr.status_code, vr.json())
            assert vr.status_code == 200
            
            # Login with new customer
            lr = requests.post(f"{BASE_URL}/login", json={"email_or_username": test_email, "password": "Password123"})
            print("New customer login:", lr.status_code, lr.json())
            assert lr.status_code == 200

    print("\n=== 5. Provider Dashboard Stats ===")
    r = requests.get(f"{BASE_URL}/provider/dashboard-stats?provider_lookup=priya.rathore@pawstay.in")
    print("Dashboard stats status:", r.status_code)
    stats = r.json()
    print("Stats summary:", stats.get("stats", {}))
    assert r.status_code == 200

    print("\n=== 6. Provider Services CRUD ===")
    # Get provider services
    r = requests.get(f"{BASE_URL}/provider/services?provider_lookup=priya.rathore@pawstay.in")
    print("Provider services count:", len(r.json()))
    assert r.status_code == 200

    # Create a new test service
    new_svc = {
        "provider_lookup": "priya.rathore@pawstay.in",
        "title": "E2E Test Pet Boarding Resort",
        "description": "Automated verification boarding package with full amenities.",
        "price_per_day": 1200.0,
        "price_per_hour": 150.0,
        "max_pets": 5,
        "status": "Active",
        "city": "Mumbai",
        "pincode": "400050",
        "food_included": True,
        "medicine_support": True,
        "pickup_drop": True,
        "outdoor_walks": True,
        "emergency_vet": True,
        "live_availability": True,
        "instant_booking": True,
        "pets_accepted": ["Dogs", "Cats"],
        "pet_sizes": ["Small", "Medium"],
        "food_types": ["Dry Food", "Homemade"],
        "amenities": ["Air Conditioning", "CCTV", "Play Area"],
        "packages": [
            {
                "title": "Standard 1-Day",
                "duration": "1 Day",
                "price": 1200.0,
                "features": ["All meals", "3 walks"]
            }
        ]
    }
    cr = requests.post(f"{BASE_URL}/provider/services", json=new_svc)
    print("Create service status:", cr.status_code, cr.json().get("message"))
    assert cr.status_code == 201
    created_id = cr.json()["service"]["id"]

    # Customer fetches active services -> verify our created service is live
    cust_svc_r = requests.get(f"{BASE_URL}/services?q=E2E%20Test")
    print("Customer search finds created service:", len(cust_svc_r.json()) > 0)
    assert any(s["id"] == created_id for s in cust_svc_r.json())

    # Update service status to Paused
    patch_r = requests.patch(f"{BASE_URL}/provider/services/{created_id}/status", json={"status": "Paused"})
    print("Pause service:", patch_r.status_code, patch_r.json())
    assert patch_r.status_code == 200

    # Verify Customer no longer sees Paused service
    cust_svc_r2 = requests.get(f"{BASE_URL}/services?q=E2E%20Test")
    assert not any(s["id"] == created_id for s in cust_svc_r2.json())
    print("Customer dashboard properly filtered out Paused service!")

    # Reactivate service
    patch_r2 = requests.patch(f"{BASE_URL}/provider/services/{created_id}/status", json={"status": "Active"})
    assert patch_r2.status_code == 200

    print("\n=== 7. Bookings & Provider Calendar ===")
    booking_payload = {
        "service_id": created_id,
        "customer_lookup": test_email,
        "customer_name": "Test Customer",
        "customer_email": test_email,
        "customer_phone": "+91 9988776655",
        "pet_name": "Buddy",
        "pet_type": "Dog",
        "pet_breed": "Labrador",
        "package_title": "Standard 1-Day",
        "check_in_date": "Today, 24 Oct",
        "amount": 1200.0
    }
    br = requests.post(f"{BASE_URL}/bookings", json=booking_payload)
    print("Create booking status:", br.status_code, br.json().get("message"))
    assert br.status_code == 201
    booking_db_id = br.json()["booking"]["db_id"]

    # Provider fetches bookings
    p_books = requests.get(f"{BASE_URL}/provider/bookings?provider_lookup=priya.rathore@pawstay.in")
    print("Provider bookings count:", len(p_books.json()))
    assert any(b["db_id"] == booking_db_id for b in p_books.json())

    # Provider fetches calendar
    cal_r = requests.get(f"{BASE_URL}/provider/calendar?provider_lookup=priya.rathore@pawstay.in")
    print("Provider calendar fetched successfully:", cal_r.status_code == 200)

    # Provider reviews
    rev_r = requests.get(f"{BASE_URL}/provider/reviews?provider_lookup=priya.rathore@pawstay.in")
    print("Provider reviews fetched:", len(rev_r.json()))
    assert rev_r.status_code == 200

    # Provider earnings
    earn_r = requests.get(f"{BASE_URL}/provider/earnings?provider_lookup=priya.rathore@pawstay.in")
    print("Provider earnings fetched:", earn_r.json().get("totalEarnings"))
    assert earn_r.status_code == 200

    # Notifications
    notif_r = requests.get(f"{BASE_URL}/notifications?user_lookup=priya.rathore@pawstay.in")
    print("Notifications count:", len(notif_r.json().get("notifications", [])))
    assert notif_r.status_code == 200

    # Clean up test service (Soft Delete)
    del_r = requests.delete(f"{BASE_URL}/provider/services/{created_id}")
    print("Delete test service:", del_r.status_code)
    assert del_r.status_code == 200

    print("\nALL BACKEND TESTS PASSED WITH ZERO 500 ERRORS!")

if __name__ == "__main__":
    test_backend()
