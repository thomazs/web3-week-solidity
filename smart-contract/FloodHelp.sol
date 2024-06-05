// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";

/*
Author: Marcos Thomaz <marcosthomazs@gmail.com>
Github: @thomazs
Whatsapp: +55 (68) 99282-9425

Desafios:
- [X] Validação que verifica a quantidade máxima de requests abertas;
- [X] validação na doação para não doar 0;
- [X] mais algum campo na struct, ex.: total de doações;
- [X] validação no getOpenRequests (quantidade máxima);
- [X] Validação que verifica a quantidade máxima de requests abertas por autor;
- [X] Validação para não criar requests com metas zeradas;
- [X] validações na criação de request (campos e duplicidade de author se request aberta);
- [X] não deixar doar para requests fechadas;
- [X] não permitir doar para request muito antiga (fecha automaticamente por tempo);
- [X] admin do contrato pode fechar requests suspeitas;
- [X] request ter um status, aí quando cadastrada, fica pendente e admin tem de aprovar;
- [X] admin aprovar a última requisição feita;
- [X] requests não aprovadas são desconsideradas das abertas
- [X] admin pode "desaprovar" uma requisição feita: efeito de suspensão;
- [X] blacklists de carteiras - admin pode cadastrar carteiras bloqueadas;
- [X] blacklists de carteiras - admin pode remover carteiras bloqueadas;
- [X] Admin pode dar privilégio de admin;
- [X] Admin pode remover privilégio de admin;
*/

struct Request {
    uint id;
    address author;
    string title;
    string description;
    string contact;
    uint timestamp;
    uint goal;
    uint balance;
    bool open;
    bool closedByAdmin;
    string reasonClosedByAdmin;
    bool approved;
}

struct Vars {
    uint a;
    uint b;
}

contract FloodHelpV2 {
    uint private constant MinValueDonation = 0;
    uint private constant MinValueRequest = 0;
    uint private constant MaxQuantityRequests = 10;
    uint private constant MaxOpenRequests = 0;  // 0 para não ter limite
    uint private constant MaxOpenRequestsByAuthor = 0;  // 0 para não ter limite
    bool private constant ValidateDuplicatedRequests = true;
    bool private constant CanDonateToClosedRequests = false;
    uint private constant TimeToAutoCloseRequests = 3600 * 24 * 30;  //tempo em segundos. 0 para desconsiderar
    bool private constant AdminNeedApproveRequests = true;  //Se estiver com True o admin precisa aprovar o pedido

    uint private lastId = 0;
    uint public qtyOpenedRequests = 0;

    mapping(uint => Request) private requests;
    mapping(address => uint) public openRequestsByAuthor;
    mapping(address => bool) private admins;
    mapping(address => bool) private blacklist;

    constructor() {
        admins[msg.sender] = true;
    }

    function openRequest(string memory title, string memory description, string memory contact, uint goal) public {
        require(MaxOpenRequests == 0 || qtyOpenedRequests >= MaxOpenRequests, unicode"Quantidade máxima de requisições abertas atingida");
        require(goal >= MinValueRequest, string.concat(unicode"É preciso informar um valor maior ou igual a: ", Strings.toString(MinValueRequest)));
        require(openRequestsByAuthor[msg.sender] < MaxOpenRequestsByAuthor, string.concat(unicode"Autor atingiu a quantidade máxima permitida: ", Strings.toString(MaxOpenRequestsByAuthor)));
        require(!existDuplicatedOpenRequest(title, msg.sender, goal), unicode"Já existe uma requisição aberta com estes parâmetros");

        lastId++;

        if (!AdminNeedApproveRequests) qtyOpenedRequests++;
        openRequestsByAuthor[msg.sender]++;
        requests[lastId] = Request({
            id: lastId,
            title: title,
            description: description,
            contact: contact,
            goal: goal,
            balance: 0,
            timestamp: block.timestamp,
            author: msg.sender,
            open: true,
            closedByAdmin: false,
            reasonClosedByAdmin: "",
            approved: !AdminNeedApproveRequests
        });
    }

    function autoCloseRequest(uint id) public {
        uint age = block.timestamp - requests[id].timestamp;
        if (TimeToAutoCloseRequests > 0 && age > TimeToAutoCloseRequests) doCloseRequest(id);
    }

    function isOpen(uint id) private view returns (bool) {
        return requests[id].open && (!AdminNeedApproveRequests || requests[id].approved);
    }

    function doCloseRequest(uint id) private {
        address author = requests[id].author;
        uint balance = requests[id].balance;
        requests[id].open = false;
        if (requests[id].approved) qtyOpenedRequests--;

        if(balance > 0){
            requests[id].balance = 0;
            payable(author).transfer(balance);
        }
    }

    function closeRequest(uint id) public {
        address author = requests[id].author;
        uint balance = requests[id].balance;
        uint goal = requests[id].goal;
        require(isOpen(id) && (msg.sender == author || balance >= goal), unicode"Você não pode fechar este pedido");

        doCloseRequest(id);
    }

    function adminCloseSuspectRequest(uint id, string memory reason) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(isOpen(id), unicode"Pedido já fechado ou ainda não aprovado");

        requests[id].closedByAdmin = true;
        requests[id].reasonClosedByAdmin = reason;
        doCloseRequest(id);
    }

    function adminApproveRequest(uint id) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(requests[id].open, unicode"Pedido já fechado");
        require(requests[id].approved, unicode"Pedido já aprovado");
        require(AdminNeedApproveRequests, unicode"Função de Aprovação do Admin está desativada");
        if (!requests[id].approved) qtyOpenedRequests++;
        requests[id].approved = true;
    }

    function adminApproveLastRequest() public {
        // aprova o último (mais recente) pedido
        adminApproveRequest(lastId);
    }

    function adminDisapproveRequest(uint id) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(requests[id].open, unicode"Pedido já fechado");
        require(!requests[id].approved, unicode"Pedido ainda não aprovado");
        require(AdminNeedApproveRequests, unicode"Função de Desaprovação do Admin está desativada");
        if (requests[id].approved) qtyOpenedRequests--;
        requests[id].approved = false;
    }

    function adminAddAddressInBlacklist(address user) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(!blacklist[user], unicode"A carteira já está na blacklist");
        blacklist[user] = true;
    }

    function adminRemoveAddressInBlacklist(address user) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(blacklist[user], unicode"A carteira não está na blacklist");
        blacklist[user] = false;
    }

    function adminAddAdminPrivilege(address user) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        require(!blacklist[user], unicode"A carteira está na blacklist e não pode ser admin");
        admins[user] = true;
    }

    function adminRemoveAdminPrivilege(address user) public {
        require(admins[msg.sender], unicode"Acesso não permitido");
        admins[user] = false;
    }

    function donate(uint id) public payable {
        autoCloseRequest(id);
        require(isOpen(id) && (msg.value > MinValueDonation), string.concat("Valor precisa ser maior que ", Strings.toString(MinValueDonation)));
        require(CanDonateToClosedRequests || isOpen(id), unicode"Não é possível fazer doações para solicitações fechadas");

        requests[id].balance += msg.value;
        requests[id].balance++; 
        if(requests[id].balance >= requests[id].goal)
            closeRequest(id);
    }
    
    function getOpenRequests(uint startId, uint quantity) public view returns (Request[] memory){
        require(quantity < MaxQuantityRequests, string.concat("Quantidade precisa ser menor que ", Strings.toString(MaxQuantityRequests)));
        Request[] memory result = new Request[](quantity);
        uint id = startId;
        uint count = 0;

        do {
            if(isOpen(id)){
                result[count] = requests[id];
                count++;
            }

            id++;
        }
        while(count < quantity && id <= lastId);

        return result;
    }

    function existDuplicatedOpenRequest(string memory title, address author, uint goal) public view returns (bool) {
        if (!ValidateDuplicatedRequests) return false;
        uint id = 0;
        while(++id < lastId){
            // Aqui uso o "open" para que o usuário não pense que sua request não foi criada caso precise da aprovação do admin
            if(requests[id].open && requests[id].author == author && requests[id].goal == goal && Strings.equal(title, requests[id].title))
                return true;
        }
        return false;
    }
}
