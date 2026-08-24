import '../models/engagement.dart';
import '../models/event_nomination.dart';
import '../models/family_member.dart';
import '../models/hotel.dart';
import '../models/transport.dart';
import '../models/vip.dart';

class DummyData {
  static List<VIP> vipList() {
    final now = DateTime.now();
    return [
      VIP(
        name: 'Sharan',
        salutation: 'Mr.',
        designation: 'CEO',
        gender: 'Male',
        protocolEquivalence: 'Secretary-level',
        organisation: 'ABC Industries',
        ministry: 'Ministry of Commerce',
        contact: '+91 9876543210',
        email: 'sharan.ceo@abc.example',
        imagePath: 'assets/images/aero-ind1.png',
        isForeign: false,
        hotel: Hotel(
          name: 'Taj West End',
          roomNumber: '101',
          stayDuration: '3 Nights',
        ),
        transport: Transport(
          carType: 'SUV',
          vehicleNumber: 'KA-01-AB-4521',
          driverName: 'Ravi',
          driverContact: '+91 9123456780',
          status: 'Pending',
        ),
        familyMembers: const [
          FamilyMember(
            salutation: 'Mrs.',
            fullName: 'Ananya Sharan',
            gender: 'Female',
            relation: 'Spouse',
          ),
        ],
        eventNominations: [
          EventNomination(
            eventName: 'RM Dinner',
            dateTime: now.add(const Duration(hours: 6)),
            venue: 'Taj West End — Banquet Hall',
          ),
          EventNomination(
            eventName: 'Inaugural Function',
            dateTime: now.add(const Duration(days: 1)),
            venue: 'Main Convention Centre',
          ),
        ],
        engagements: [
          Engagement(
            eventName: 'Welcome Dinner',
            dateTime: now,
            rsvpStatus: 'Confirmed',
          ),
        ],
        remarks: ['Prefers vegetarian meals'],
        specialRequests: ['Security escort required'],
      ),
      VIP(
        name: 'Dr. Michael Thompson',
        salutation: 'H.E.',
        designation: 'Minister',
        gender: 'Male',
        protocolEquivalence: 'Cabinet Minister',
        organisation: 'UK Government',
        ministry: 'Ministry of Defence (UK)',
        contact: '+44 7700 900123',
        email: 'm.thompson@gov.uk.example',
        imagePath: 'assets/images/aero-ind1.png',
        isForeign: true,
        nationality: 'United Kingdom',
        passportNumber: 'UKX98456321',
        passportValidity: now.add(const Duration(days: 800)),
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
          vehicleNumber: 'KA-05-CD-7788',
          driverName: 'Arjun Singh',
          driverContact: '+91 9988776655',
          status: 'Completed',
          flightNumber: 'BA119',
          arrivalTime: now.add(const Duration(hours: 2)),
          arrivalTerminal: 'T2',
          arrivalLocation: 'Kempegowda International Airport',
        ),
        familyMembers: [
          FamilyMember(
            salutation: 'Mrs.',
            fullName: 'Elizabeth Thompson',
            gender: 'Female',
            relation: 'Spouse',
            passportNumber: 'UKX11223344',
            passportValidity: now.add(const Duration(days: 600)),
          ),
          FamilyMember(
            salutation: 'Mr.',
            fullName: 'James Thompson',
            gender: 'Male',
            relation: 'Son',
            passportNumber: 'UKX55667788',
            passportValidity: now.add(const Duration(days: 400)),
          ),
        ],
        eventNominations: [
          EventNomination(
            eventName: 'Inaugural Function',
            dateTime: now.add(const Duration(days: 1, hours: 2)),
            venue: 'Main Convention Centre',
          ),
          EventNomination(
            eventName: 'Valedictory Function',
            dateTime: now.add(const Duration(days: 4)),
            venue: 'Palace Grounds Auditorium',
          ),
          EventNomination(
            eventName: 'RM Dinner',
            dateTime: now.add(const Duration(days: 2, hours: 5)),
            venue: 'Rashtrapati Bhavan Banquet',
          ),
        ],
        engagements: [
          Engagement(
            eventName: 'Inaugural Ceremony',
            dateTime: now.add(const Duration(days: 1)),
            rsvpStatus: 'Confirmed',
          ),
          Engagement(
            eventName: 'Bilateral Defence Meeting',
            dateTime: now.add(const Duration(days: 2)),
            rsvpStatus: 'Confirmed',
          ),
        ],
        remarks: [
          'Requires high security corridor',
          'Protocol team coordination mandatory',
        ],
        specialRequests: [
          'Halal Food',
          'Interpreter (Hindi)',
          'Secure Communication Line',
        ],
        foodPreferences: 'Halal, No Shellfish',
      ),
    ];
  }
}
