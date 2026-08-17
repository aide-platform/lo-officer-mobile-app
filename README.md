# liaison_officer

Liaison Officer mobile app for bel.com

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

LO Login
Upon receiving the system-generated email, the nominated LO accesses the portal through the application URL and authenticates via Email OTP to log in. The Organisation Name and Organisation Type are automatically populated in the LO's profile from the parent organisation record   the LO does not need to select or enter these details.
LO.5.2 LO Profile Form   Fields
Personal Details:
Salutation   Searchable Dropdown; pre-filled from basic details; editable
First Name   pre-filled from basic details; editable
Last Name   pre-filled from basic details; editable
Gender   Dropdown
Date of Birth   Date Picker
Age   auto-calculated from Date of Birth; read-only
Rank   free-text
Designation   free-text
Recent Passport Size Photograph   image upload
Organisation Details:
Organisation Name   auto-populated from the parent organisation record; read-only
Organisation Type   auto-populated from the parent organisation record; read-only
Organisation ID Number / Service ID Number   free-text; a single field capturing either the Organisation ID or Service ID as applicable
Organisation ID Badge   Front Photo   image upload
Organisation ID Badge   Back Photo   image upload
Identity Details:
Aadhaar Number   numeric
Aadhaar Card   Front Photo   image upload
Aadhaar Card   Back Photo   image upload
Contact Details:
Official Email ID   email text field
Personal Email ID   email text field
Official Contact Number   free-text with country code
Personal Contact Number   free-text with country code
WhatsApp Number   free-text with country code; with an option to indicate whether it is the same as the Official or Personal contact number
Signature:
Signature   image upload
Previous LO Experience:
Has the LO served as a Liaison Officer in a previous Aero India or similar event?   Yes / No
If Yes, the following details are captured in a repeater section for each previous experience:
Event Name   free-text
Year   numeric
Role / Responsibilities   free-text
Delegate Details   free-text; details of the delegate(s) the LO was assigned to during that event
Availability:
Available From Date Date Picker
Available To Date   Date Picker
Languages Known   multi-select
LO.5.3 Profile Submission
Once all mandatory details and documents are provided, the LO submits their profile. Upon submission, the profile status is updated to Submitted and becomes visible to the LO Committee Nodal Officer and the Organisation Representative.

LO.6 LO Committee Nodal Officer  LO Profile Review
The LO Committee Nodal Officer has a consolidated view of all LO profiles submitted across all organisations. The listing can be filtered by Organisation, Organisation Type, Language, Availability, and Submission Status.
The Nodal Officer can open and view each submitted LO profile in full detail   including all entered information, uploaded documents, and previous experience details. 
LO.7 Badge Assignment to LOs
LOs do not receive a badge by default. The LO Committee Nodal Officer shall have the provision to assign badges to one or more LOs from the badge quota allocated to the LO Committee by the Badge and Vehicle Pass Management Committee. The badge type shall be the same for all LOs.
The LO Committee Nodal Officer shall select one or multiple LOs from the LO listing and assign badges in bulk. The system shall prevent badge assignment beyond the badge quota allocated to the LO Committee.
Once the badge has been assigned, the Badge Download option shall be available to the respective Organisation Head, the LO Committee Nodal Officer, and the respective LO for downloading the assigned badge.
LO.8 LO Assignment to Delegates
LO.8.1 Assign LOs to Delegates
The LO Committee Nodal Officer assigns LOs to delegates whose RSVP has been marked as Attending. Assignment is based on operational criteria such as previous experience, language proficiency, organisation type, and protocol requirements.
Assignment Rules:
One LO can be assigned to multiple delegates
One delegate can have multiple LOs assigned to them
The Nodal Officer has the provision to modify or remove LO assignments at any point in time
Upon assignment, the LO receives an automatic email notification  informing them of their assignment and the delegate details.


LO.8.2 Task Assignment to LOs
After assigning LOs to delegates, the LO Committee Nodal Officer assigns coordination tasks to each LO. Since one LO can be assigned to multiple delegates, every task assigned to an LO is linked to a specific delegate so that the task is VIP-specific and traceable. A task can either be selected from the Activity Master or created as a custom LO-specific task.
Assign Task — Fields:
Assigned LO — Searchable Dropdown listing all LOs — mandatory
Assigned Delegate — Searchable Dropdown listing delegates assigned to the selected LO — mandatory; every task is linked to a specific delegate under the selected LO
Task Source — Radio Button — mandatory:
Select from Activity Master
Create Custom Task
If Activity Master is selected:
Activity — Searchable Dropdown listing activities from the Activity Master; upon selection, the Task Title and Task Description are automatically populated and remain editable
Scheduled Date — Date Picker — optional
Scheduled Time — Time Picker — optional
Location / Venue — free-text — optional
Remarks — free-text — optional
If Create Custom Task is selected:
Task Title — free-text — mandatory
Task Description — free-text — mandatory
Scheduled Date — Date Picker — optional
Scheduled Time — Time Picker — optional
Location / Venue — free-text — optional
Remarks — free-text — optional
The LO Committee Nodal Officer has the provision to add, edit, or reassign tasks at any time. Whenever a task is updated or reassigned, the concerned LO receives an automatic email notification.
LO.8.3 Task Monitoring
The LO Committee Nodal Officer can monitor the execution status of all assigned tasks. The task listing displays each task along with the assigned LO, the specific delegate the task is linked to, the task title, scheduled date and time, location, and the current status as updated by the LO. The Nodal Officer can filter tasks by LO, Delegate, Task Source (Activity Master or Custom), Scheduled Date, and Status.

LO.9 LO Login   Post Assignment
LO.9.1 View Assignment and Delegate Details
Upon assignment, the LO can log in to the portal via Email OTP and view the following for each delegate assigned to them:
Delegate Profile Details:
Full Name, Salutation, Decoration, Designation, Gender, Protocol Equivalence
Organisation / Ministry details
Contact Number and Email Address
Passport details where applicable
Family Member Details:
List of family members accompanying the delegate
Salutation, Full Name, Gender, Relation, Passport Number, and Passport Validity (where applicable)
Event Nominations:
List of events the delegate has been nominated for   such as RM Dinner, Inaugural Function, Valedictory Function, and others   along with event date, time, and venue details
Vehicle / Transport Details:
Vehicle Type, Vehicle Number, Driver Name, and Driver Contact Number for vehicles assigned to the delegate

LO.9.2 View and Update Arrival and Departure Details of Assigned VIPs
The LO has the provision to view the arrival and departure details of their assigned delegates and update these details through their login.
Arrival Details:
Flight Number   free-text
Terminal   free-text
Arrival Date   Date Picker
Arrival Time   Time Picker
Connecting Flights   Repeater section: Flight Number, Terminal, Date, Time
Departure Details:
Flight Number   free-text
Terminal   free-text
Departure Date   Date Picker
Departure Time   Time Picker
Connecting Flights   Repeater section: Flight Number, Terminal, Date, Time
Updates made by the LO to arrival and departure details are reflected in the system and are visible to the LO Committee Nodal Officer.

LO.9.3 Task Status Updates
The LO can view and update the status of each assigned task through their login. Tasks are displayed grouped by delegate, so the LO can clearly see which tasks are linked to which delegate. For each task, the available status options are:
Pending
In Progress
Completed
The task listing in the LO login displays the Task Title, Task Description, Linked Delegate Name, Scheduled Date and Time (where captured), Location, and current Status. Status updates made by the LO are immediately visible to the LO Committee Nodal Officer.

LO.9.4 Notification Alerts
The LO receives email and in-portal notifications for:
New task assignments or updates to existing tasks
Changes to delegate travel, accommodation, or event details
Upcoming scheduled tasks   alerts triggered at a configurable time before the scheduled task datetime

