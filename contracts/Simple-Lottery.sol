//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract BasicAuction {
    address payable public owner;
    mapping(address => uint) public bids;
    uint public price;
    address payable public leader;
    uint constant public step = 0.01 ether;
    uint public startBlock;
    uint public endBlock;
    
    enum Status{
        Started,
        inProgress,
        Ended,
        Canceled
    }
    Status auctionStatus;
    
    struct Params{
        address payable seller;
        uint startBlock;
        uint endBlock;
    }
    
    event participantGotHisMoney(address recipient, address msgsender, uint value, string usecase);
    event checkTest(string value);
    
    constructor() { //Params memory _params
        owner = payable(msg.sender); //_params.seller
        startBlock = block.number; //_params.startBlock
        endBlock = startBlock + 4; //_params.endBlock
        price = 0.1 ether;
        auctionStatus = Status.Started;
    }
    
    ///
    ///*********MODIFIERS*********
    ///
    
    modifier notOwner(){ //все, кроме продавца
        require(msg.sender != owner);
        _;
    }
    modifier afterStart(){ //только после блока начала торгов
        require(block.number >= startBlock);
        _;
    }
    modifier notEnded(){ //только если торги не завершились
        require(auctionStatus != Status.Ended && auctionStatus != Status.Canceled);
        _;
    }
    modifier auctionStarted(){ //только если статус Started
        require(auctionStatus == Status.Started || auctionStatus == Status.inProgress);
        _;
    }
    modifier onlyOwner() { //только продавец может быть допущен
        require(msg.sender == owner);
        _;
    }
    modifier beforeEnd() { //если блоки дошли до конечной, не принимаем оплату
        require(block.number < endBlock);
        _;
    }
    
    ///
    ///*********END OF MODIFIERS*********
    ///
    
    
    ///РАЗМЕЩЕНИЕ СТАВКИ
    function placeaBid() public payable notOwner afterStart beforeEnd returns(bool){
        uint currentBid;
        if(auctionStatus != Status.inProgress){
            auctionStatus = Status.inProgress;
        }
        if(block.number != endBlock){
            currentBid = msg.value + bids[msg.sender];  //обновляем текущую ставку
            bids[msg.sender] = currentBid;              //обновляем ставку для участника
            if(currentBid >= price){                    //проверяем, не больше ли текущая ставка, чем лидирующая
                leader = payable(msg.sender);        //если больше, то меняем лидера аукциона
                price = currentBid + step;             //и обновляем лидирующую ставку
            }
        }
        if((block.number + 1) >= endBlock){
            auctionStatus = Status.Ended;
        }
        return true;
    }
    
    ///ОСТАНОВКА АУКЦИОНА
    function StopAuction() public onlyOwner{
        auctionStatus = Status.Canceled;
    }
    
    ///ВОЗВРАТ СРЕДСТВ
    function giveMyMoneyBack() public {
        uint value;
        address payable recipient;
        string memory usecase;
        
            // АУКЦИОН CANCELED        
        if(auctionStatus == Status.Canceled){ // При отмене аукциона, выводят все одинаково
            recipient = payable(msg.sender);
            value = bids[msg.sender];
            usecase = "Canceled";
        }else if(auctionStatus == Status.inProgress){
            
            // ДОСРОЧНЫЙ ВЫХОД
            if(msg.sender != leader && msg.sender != owner){ // Досрочный вывод, если не лидер и не владелец, только для обычных участников, кто решил, что уже не выиграет
                recipient = payable(msg.sender);
                value = bids[msg.sender];
                usecase = "forwarded";                
            }
        }else if(auctionStatus == Status.Ended){
            
            // LEADERS
            if(msg.sender == leader){ // Лидер забирает сдачу и купленное имущество
                recipient = leader;
                value = bids[leader] - (price - step); // мы отнимаем от price step т.к. изначально добавили к price step
                // Здесь должно быть присвоение владельца msg.sender чему-либо
                usecase = "leader";
                
            // OWNERS
            }else if(msg.sender == owner){ // Владелец забирает сумму, полученную с продажи
                recipient = owner;
                value = price - step;
                usecase = "owner";
                
            // ЗАВЕРШЕНИЕ АУКЦИОНА ДЛЯ ВСЕХ            
            }else{
                recipient = payable(msg.sender); //Не продавец, не лидер, обычный участник забирает свои средства по завершении аукциона
                value = bids[msg.sender];
                usecase = "other cases";
            }
        }
                
        recipient.transfer(value);  //отправка средств тому, кто вызвал эту функцию
        emit participantGotHisMoney(recipient, msg.sender, value, usecase);
    }
    
    ///
    ///*********ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ**********
    ///
    
    function currentBlock() public view returns(uint){
        return block.number;
    }
    
    function contractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function currentStatus() public view returns(string memory){
        string memory result;
        if(auctionStatus == Status.Started){
            result = "Started";
        }else if(auctionStatus == Status.inProgress){
            result = "inProgress";
        }else if(auctionStatus == Status.Ended){
            result = "Ended";
        }else{
            result = "Canceled";
        }
        return result;
    }
    
    function changeStatus(Status _status) public returns(bool) {
        auctionStatus = _status;
        return true;
    }
    
}