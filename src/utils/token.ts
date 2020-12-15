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
  Decimals = 'decimals',
  Address = '_this_address'
}

export function toZRC1(init: InitItem[]) {
  const contractOwner = init.find((el) => el.vname === Fields.ContractOwner)?.value;
  const name = init.find((el) => el.vname === Fields.Name)?.value;
  const symbol = init.find((el) => el.vname === Fields.Symbol)?.value;
  const address = init.find((el) => el.vname === Fields.Address)?.value;
  const decimals = init.find((el) => el.vname === Fields.Decimals)?.value;

  if (!contractOwner || !name || !symbol || !address || !decimals) {
    throw new Error('Is not ZRC');
  }

  return {
    decimals: Number(decimals),
    contractOwner,
    name,
    symbol,
    address
  };
}
