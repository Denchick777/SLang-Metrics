// Core units to represent basic SLang types  (WIP - not all features are fully implemented!!! )
// Version 0.75 June 22nd 2018

val unit Bit
    const is
         0b0, 0b1
    end

    & alias and(other: as this): as this do
        if this = 0b0 then
            return 0b0
        elsif other = 0b0 then
            return 0b0
        else
            return 0b1
        end
    end

    | alias or(other: as this): as this do
        if this = 0b1 then
            return 0b1
        elsif other = 0b1 then
            return 0b1
        else
            return 0b0
        end
    end

    ^ alias xor(other: as this): as this do
        if this = other then
            return 0b0
        else
            return 0b1
        end
    end

    ~ alias not(): as this do
        if this = 0b0 then
            return 0b1
        else
            return 0b0
        end
    end

    +(other: as this): as this do
        /// Definition of addition
        if this = 0b0 then
            return other
        elsif other = 0b1 then
            raise "Bit overflow"
        else
            return 0b1
        end
    end // +

    -(other: as this): as this do
        /// Definition of subtraction
        if this = other then
            return 0b0
        elsif this = 0b1 then
            return 0b1
        else
            raise "Bit underflow"
        end
    end // -
end

if true then 
    if false then
        a is 10
    else
        b is 12
    end
elsif a > b then
    none
elsif a < b then
    if true then
        none
    else 
        none
    end
else
    b is 15
end

/*
    CC == 6 //true
*/
