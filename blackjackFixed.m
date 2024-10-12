% clc
% clear
% close all
clc
clear


sSize = 16; %sprite size, based on actual size on sprite sheet
zFactor = 5; %zoom factor, based on how big you want displayed images to be
BGC = [0 128 0]; %background color, green
sprite_sheet = "retro_images/retro_cards.png";
%sprite_sheet = "poker_assets/spritesheet.png";
engine_scene = simpleGameEngine(sprite_sheet, sSize, sSize, zFactor, BGC);
grid = ones(10); %1 is blank on sprite sheet
card_num = 1:52; %# of the card in the deck
card_value = [1:10 10 10 10 1:10 10 10 10 1:10 10 10 10 1:10 10 10 10]; % value of the card
card_value(1)=11;
card_value(14)=11; %set aces to 11
card_value(27)=11;
card_value(40)=11;

card_sprite = 21:72; %# of card in sprite sheet
card_back = 4;
dealer_hand = [0,0];
player_hand = [0,0];
dValue=0;
bank=1000; %starting bank
answer=1; %player wants to play first time



while bank > 0 && answer==1 %if player has money and wants to play
    grid = ones(10); %resets cards to blank
grid(1,10) = card_back;
   drawScene(engine_scene,grid);
    textDealer = text(10,100,1,'Dealer:');
    textPlayer = text(10,600,1,'Player:');
    textBank = text(10,750,1,['Bank:',num2str(bank)]);
    drawScene(engine_scene,grid); %drawing initial scene
    pause(1);


%bet
currentbet = inputdlg('How much would you like to wager?');
currentbet = str2double(currentbet);
while currentbet>bank
    currentbet = inputdlg('Your bet cannot exceed your balance. How much would you like to wager?');
    currentbet = str2double(currentbet); %asking for wager and registering it as the bet
end
bank=bank-currentbet; %taking bet from the bank
    textBet = text(10,300,1,['Current bet:',num2str(currentbet)]);
    delete(textBank)
    textBank = text(10,750,1,['Bank:',num2str(bank)]); %displaying new bet and bank
%
%dealing
shuffledeck=randperm(52);%shuffling deck
    dHand = [shuffledeck(end),shuffledeck(end-1)]; %gives dealer 2 random cards in the deck
    pHand = [shuffledeck(1),shuffledeck(2)]; %gives player 2 random cards in the deck
    pValue = sum(card_value(pHand)); %gets value of the cards in the olayer's hand
    grid([2 9],[5 6]) = card_back;
    drawScene(engine_scene,grid); %draw scene
    pause(1);
    grid(2,6) = card_sprite(dHand(2)); %flips dealers first card
    grid(9,[5 6]) = card_sprite(pHand); %flips players cards
    drawScene(engine_scene,grid);
    textStay = text(150,375,1,'Stay');
    textHit = text(600,375,1,'Hit'); 
    grid(6,[3 8]) = 11;
    drawScene(engine_scene,grid); %gives options to stay or hit and will register the click
    [r,c,b] = getMouseInput(engine_scene);
    i = 1;
    card=3;
    while c > 5 %hit
        pHand(end+1)=card_num(shuffledeck(card));  %adding next card to hand if hits
        pValue = sum(card_value(pHand)); %adding card value to hand value
        grid(9,6+i) = card_sprite(pHand(2+i)); 
        drawScene(engine_scene,grid);
        [r,c,b] = getMouseInput(engine_scene);
        card=card+1; %adding to next card and i value in case another hit
        i=i+1;
    end
   
    
    if c<5 %if not hitting 
        grid(2,5) = card_sprite(dHand(1)); %flips dealers second card
        card=2;
        i=1;
        dValue = sum(card_value(dHand)); %gets value of the cards in the hand
        drawScene(engine_scene,grid);
        pause(1)
        while dValue < 17 && pValue<=21 %check if dealer has at least 17 and keeps drawing cards until they do. Doesn't draw if player busted
                dHand(end+1)=card_num(shuffledeck(end-card)); %adding next card to dealers hand
                dValue=sum(card_value(dHand)); %adding to hand value
                grid(2,6+i) = card_sprite(dHand(end));
                drawScene(engine_scene,grid);
                pause(1); %drawing scene
                card=card+1;%adding to next card and i value in case another hit
                i=i+1;
             
    
     
        end
        if pValue>21 %if the player still has over 21
       delete(textBet)
       textFinal=text(275,500,1,'Player busts, Dealer Wins!');
        drawScene(engine_scene,grid); %player busts, no winnings
        pause(1) %drawing result
        delete(textFinal)%deleting the result text before redrawing
   
        elseif pValue == 21 && length(pHand)==2
            textFinal = text(500,500,1,'Blackjack!');
             delete(textBank)
             delete(textBet)
             bank=bank+2.5*currentbet; %on a blackjack, the player collects 1.5 times their normal winnings because it pays back 3:2
             textBank = text(10,750,1,['Bank:',num2str(bank)]);
             drawScene(engine_scene,grid); %drawing result
             pause(1)
             delete(textFinal) %deleting the result text before redrawing
    elseif dValue>21 %if dealer has over 21
             textFinal = text(500,500,1,'Dealer busts, Player wins!');
             delete(textBank)
             delete(textBet)
             bank=bank+2*currentbet; %the dealer busts, and the player collects their winnings
             textBank = text(10,750,1,['Bank:',num2str(bank)]);
             drawScene(engine_scene,grid);%drawing result
             pause(1)
             delete(textFinal)%deleting the result text before redrawing
        elseif dValue > pValue %if the dealer has greater than the player's value
            textFinal = text(500,500,1,'Dealer Wins!'); 
            delete (textBet) %dealer wins, no winnings
        drawScene(engine_scene,grid);%drawing result
        pause(1)
        delete(textFinal)%deleting the result text before redrawing
        elseif pValue>dValue %if the player has greater than the dealer's value
             textFinal = text(500,500,1,'Player Wins!');
             delete(textBank)
             delete(textBet)
             bank=bank+2*currentbet; %player wins, collects winnings
              textBank = text(10,750,1,['Bank:',num2str(bank)]);
             drawScene(engine_scene,grid);%drawing result
             pause(1)
             delete(textFinal)%deleting the result text before redrawing
        elseif pValue==dValue %if player value is equal to dealer
            textFinal = text(500,500,1,'Push, money back!');
             delete(textBank)
             delete(textBet)
             bank=bank+currentbet; %push, player collects their original bet
              textBank = text(10,750,1,['Bank:',num2str(bank)]);
             drawScene(engine_scene,grid);%drawing result
             pause(1)
             delete(textFinal)%deleting the result text before redrawing
        end
  
  
end
   
answer = inputdlg('Would you like to continue playing? Enter 1 for yes, or any other answer for no'); %ask if player wants to play again
answer = str2double(answer); %registering as 1 or not
endDelete(textBank,textDealer,textPlayer,textHit,textStay) 
grid=ones(10); %deleting all text with the fuctions, as well as sprites
end
textEnd = text(275,300,1,'Thank you for playing!'); %if player doesn't want to play again, end game
    drawScene(engine_scene,grid);


function endDelete(banktext,dealertext,playertext,hittext,staytext)
delete(banktext)
delete(dealertext)
delete(playertext)
delete(hittext)
delete(staytext)
end 

  
   