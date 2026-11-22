# Goal

Our goal is to create a mobile application that will serve the community of players of beach volleyball to organize their plays,
dates at the court, replacement players and potential financial compensations for playing as a replacement. Also it will serve to schedule regular training plays and groups around them.

## Users of the application

There will be two user types in the application:
1. General user - able to be part of one or more teams or to create own team and manage it
2. Admin user - able to manage users, their accesses or restrictions

## Non-functional requirements

### Security:

1. The application will enable registration of a new user via use of e-mail address and authentication code sent at a first logon.
2. the application will enable face recognition logon confirmation for subsequent logins
3. In case of non-use of the face recognition authentication, the app will record the credentials at the mobile device

### Design

1. The design will be as simple as possible, enabling main functionality groups.
2. The graphics should be compelling, main colors would be blue and yellow
3. The design will be responsive to reflect dimension of the device it is open at
4. The application languages will be English and Slovak

## Functional requirements

### User setup

1. Create a user on a first login with confirmation via e-mail
2. Define name to show to others
3. Enable face recognition ID via mobile phone functionalities
4. Set up the language
5. Button for user settings, enabling to change the password, language and name to show
   
### Teams owned

1. Create a new owned team, defining 
   - Season (winter or summer) / year
   - playground place
   - day of the week
   - time of start
   - time of the end
   - Season start date
   - Season end date
   - Total charge for the court
   - Charge per person
2. define team members
   - application users or
   - external users, not using the application yet - via e-mail address or whatsapp account
3. manage owned team
   - add user
   - remove user
   - send a notification to all members

### Replacement groups

1. Creation of an own replacement group - group of players in the application that can be contacted in case someone is missing from any of the owned teams
2. Call-out for replacement in case someone is missing from an owned team 
   - the notification will go to all members of the replacement group
   - The definition of the call-out will contain expected charge from player that applies and is accepted
3. Application for called-out replacement 
   - sends notification to the team owner
   - needs to be confirmed by the team owner
4. Charge for replacement - pays the replacement player to the team where he/she replaces some player