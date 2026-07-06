/*
* This file is part of the CMaNGOS Project. See AUTHORS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "Chat/Chat.h"
#include "Entities/Pet.h"

bool ChatHandler::HandlePetLevelLoyaltyCommand(char* args)
{
    if (!*args)
        return false;

    Pet* pet = getSelectedPet();
    if (!pet)
        return false;

    if (pet->getPetType() != HUNTER_PET)
        return false;

    uint32 levelupCount;
    if (!ExtractOptUInt32(&args, levelupCount, 1))
        return false;

    uint32 loyaltyLevel = pet->GetLoyaltyLevel();
    for (; loyaltyLevel < BEST_FRIEND && levelupCount > 0; levelupCount--)
    {
        // Pet::ModifyLoyalty() only levels up loyalty once the pet has also earned enough kill XP
        // to clear its per-level XP requirement; this command is meant to force the level up outright,
        // so clear that requirement first instead of leaving it to silently block the level up.
        pet->UpdateRequireXpForNextLoyaltyLevel(std::numeric_limits<uint32>::max());
        pet->ModifyLoyalty(pet->GetStartLoyaltyPoints(loyaltyLevel + 1));
        ++loyaltyLevel;
    }
    return true;
}
