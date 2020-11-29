/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
interface InitItem {
  type: string;
  value: string;
  vname: string;
}

enum Fields {
  ContractOwner = 'contract_owner',
  Name = 'name',
  Symbol = 'symbol',
  Address = '_this_address'
}

export function toZRC1(init: InitItem[]) {
  const vnames = init.map((el) => el.vname);

  [Fields.ContractOwner, Fields.Name, Fields.Symbol].forEach((field) => {
    if (!vnames.some((el) => el === field)) {
      throw new Error('not found vname ' + field);
    }
  });

  const contractOwner = init.find((el) => el.vname === Fields.ContractOwner)?.value;
  const name = init.find((el) => el.vname === Fields.Name)?.value;
  const symbol = init.find((el) => el.vname === Fields.Symbol)?.value;
  const address = init.find((el) => el.vname === Fields.Address)?.value;

  return {
    contractOwner,
    name,
    symbol,
    address
  };
}
