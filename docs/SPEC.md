# BeachTeams - product specification

<!-- > The one document you must write yourself (15-30 minutes). Agents read it before every task.
> Keep it short and true. Update it when the product changes; do not let it rot.
-->

## Vision
Our goal is to create a mobile application that will serve the community of players of beach volleyball to organize their plays,
dates at the court, replacement players and potential financial compensations for playing as a replacement. Also it will serve to schedule regular training plays and groups around them.

## Users and roles
The users of the application will be in total up to 50 members of the beachvolleyball community.
There will be two user types in the application:
1. General user - able to be part of one or more teams or to create own team and manage it
2. Admin user - able to manage users, their accesses or restrictions

## Platforms and distribution
- iOS and Android via Expo. Distribution to friends: Expo Go / EAS builds (non-commercial, no app-store release required).
- Languages: Slovak + English, user can switch between them

## Core features (the big picture, not requirements)
The application will have three categories of functionalities:
- User setup
- Management of own teams
- Management of replacement groups
- Confirmation of play

### User setup

1. Create a user on a first login with confirmation via e-mail
2. Define name to show to others
3. Enable face recognition ID via mobile phone functionalities
4. Set up the language
5. Button for user settings, enabling to change the password, language and name to show
   
### Management of teams owned

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

### Management of replacement groups

1. Creation of an own replacement group - group of players in the application that can be contacted in case someone is missing from any of the owned teams
2. Call-out for replacement in case someone is missing from an owned team 
   - the notification will go to all members of the replacement group
   - The definition of the call-out will contain expected charge from player that applies and is accepted
3. Application for called-out replacement 
   - sends notification to the team owner
   - needs to be confirmed by the team owner
4. Charge for replacement - pays the replacement player to the team where he/she replaces some player

### Confirmation of play
1. Selection of one of the teams where a logged-in user is a team member
2. Either confirmation of a participation in play in a particular team play at a particular date and time
3. Or confirmation of non-participation in play in a particular team play at a particular date and time

### Core features
1. The design will be as simple as possible, enabling main functionality groups.
2. The graphics should be compelling, main colors would be blue and yellow
3. The design will be responsive to reflect dimension of the device it is open at
4. The application languages will be English and Slovak

## Data

1. Personal data
   - User name
   - User e-mail
   - User password
   - If user cancels their account, all his data are removed, except of cleared and uncleared debts. 

2. Owned teams data
   - Season (winter or summer) / year
   - playground place
   - day of the week
   - time of start
   - time of the end
   - Season start date
   - Season end date
   - Total charge for the court
   - Charge per person

3. Replacement group data
    - name of the replacement group (visible to the user that has defined it only)
    - names of players in the replacement group
    - contacts to player in the replacement group

## Constraints
- Budget: free tiers only (Supabase free, Expo free, GitHub).
- Privacy: collect the minimum; no tracking/ads/analytics.
- Offline / poor connectivity expectations: none, in such case application will not show anything
- Accessibility expectations:none

## Non-goals
- Never share a user's password with any other user
- Never delete user without asking for confirmation
- Never do anything that is not explicitely described in the requirements or not approved by human
- 

## Glossary
- Owned team: group of beachvolleyball players that meet regularly to play beachvolleyball
- Replacement group: group of players that are not part of a particular owned team but can be invited to play in case somebody from the Owned team is missing for the particular play time
- Team member: a user that is not owner of the particular Owned team, but is defined by the team owner as a team member

## Decisions log
Link design notes in `docs/design/` and record big decisions here in one line each.
