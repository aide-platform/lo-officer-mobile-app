import '../models/engagement.dart';
import '../models/hotel.dart';
import '../models/transport.dart';
import '../models/vip.dart';

class DummyData {
  static List<VIP> vipList() {
    return [

      // 🇮🇳 Domestic VIP
      VIP(
        name: 'Sharan',
        designation: 'CEO - ABC',
        contact: '+91 9876543210',
        imagePath: 'assets/images/aero-ind1.png',
        isForeign: false,
        hotel: Hotel(
          name: 'Taj West End',
          roomNumber: '101',
          stayDuration: '3 Nights',
        ),
        transport: Transport(
          carType: 'SUV',
          driverName: 'Ravi',
          driverContact: '+91 9123456780',
          status: 'Pending',
        ),
        engagements: [
          Engagement(
            eventName: 'Welcome Dinner',
            dateTime: DateTime.now(),
            rsvpStatus: 'Confirmed',
          ),
        ],
        remarks: ['Prefers vegetarian meals'],
        specialRequests: ['Security escort required'],
      ),

      // 🌍 Foreign Dignitary
      VIP(
        name: 'Dr. Michael Thompson',
        designation: 'Minister - UK',
        contact: '+44 7700 900123',
        imagePath: 'assets/images/aero-ind1.png',
        isForeign: true,
        nationality: 'United Kingdom',
        passportNumber: 'UKX98456321',
        language: 'English',
        timeZone: 'GMT',
        visaStatus: 'Approved',
        securityClearanceStatus: 'Cleared by MoD',

        hotel: Hotel(
          name: 'The Leela Palace',
          roomNumber: 'Presidential Suite',
          stayDuration: '5 Nights',
        ),

        transport: Transport(
          carType: 'Bulletproof Sedan',
          driverName: 'Arjun Singh',
          driverContact: '+91 9988776655',
          status: 'Completed',
          flightNumber: 'BA119',
          arrivalTime: DateTime.now().add(Duration(hours: 2)),
          arrivalTerminal: 'T2',
          arrivalLocation: 'Kempegowda International Airport',
        ),

        engagements: [
          Engagement(
            eventName: 'Inaugural Ceremony',
            dateTime: DateTime.now().add(Duration(days: 1)),
            rsvpStatus: 'Confirmed',
          ),
          Engagement(
            eventName: 'Bilateral Defence Meeting',
            dateTime: DateTime.now().add(Duration(days: 2)),
            rsvpStatus: 'Confirmed',
          ),
        ],

        remarks: [
          'Requires high security corridor',
          'Protocol team coordination mandatory'
        ],

        specialRequests: [
          'Halal Food',
          'Interpreter (Hindi)',
          'Secure Communication Line'
        ],

        foodPreferences: 'Halal, No Shellfish',
      ),
    ];
  }
}