import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

void main() {
  MyLoAssignmentDto parse(Map<String, dynamic> json) =>
      MyLoAssignmentDto.fromJson({'assignmentId': 'a1', ...json});

  test('accommodation status matches the web LO Assignments screen', () {
    expect(
      parse({'accommodationConsidered': false}).accommodationStatus,
      'Not Considered',
    );
    expect(
      parse({
        'accommodationConsidered': true,
        'accommodationArranged': true,
      }).accommodationStatus,
      'Allotted',
    );
    expect(
      parse({'accommodationConsidered': true}).accommodationStatus,
      'Considered',
    );
    expect(parse({}).accommodationStatus, 'Considered');
  });

  test('country accommodation flag is read', () {
    expect(
      parse({'countryAccommodationRequired': true})
          .countryAccommodationRequired,
      isTrue,
    );
    expect(parse({}).countryAccommodationRequired, isNull);
  });
}
