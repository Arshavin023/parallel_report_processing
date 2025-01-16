import math

# List of datim_ids
datim_ids = ['jJwndfpsyuh', 'afAd7DGCtCs', 'C0810vNbF7i', 'mLQcXu4kwJW', 'A1xxdELs2fm',
                 'zrmFDKuEwvY', 'IU4lXhgmRYl', 'KYGNqrZrhD7', 'lbahxODJXCM', 'IT1CAw7NmXo',
                 'XHXGJpskTtQ', 'hZUBGSg9eB9', 'gNfPmS9Pmbr', 'LBgwDTw2C8u', 'VJAGNlxdeyv',
                 'yHC4slVfeDb', 'gR8LIQkSMn8', 'aG634TzZo19', 'ikK22AdDdjA', 'FMA9UDB6kWE',
                 'zyNpCab6d3Z', 'CSK6FErktDd', 'YkKtpQkI0DA', 'dmrFYPiuKAA', 'lQTQ4TXvJyY',
                 'rVULNREkq0q', 'w5eSPCsTUXh', 'CTL8iNhJwBB', 'nnjEYKiOt3O', 'j4Hmo4w9Lia',
                 'wj03dAcVomS', 'Ptnp8JFEIm0', 'O7ZT10hlis4', 'jTiweHpRvd4', 'mxeORAzNzal',
                 'QWkhj6LkQMO', 'x46m45UoY7H', 'wByDgXTFiHI', 'OX2RLpRPBK4', 'c3kbJokGc4i',
                 'cYvZUmSQTyQ', 'ulunZz6L3UM', 'uz0kFwLBXqH', 'tnkmHqHxeyp', 'GuCdZy1Pkkx',
                 'jfE3XKBsFEv', 'Xa1RCh7Z2aC', 'C1vafUnVo60', 'IBL5Nck2ZZK', 'Bd9zC4esWvG']

# Split datim_ids into batches of 10
batch_size = 10
total_batches = math.ceil(len(datim_ids) / batch_size)
datim_batches = [datim_ids[i * batch_size:(i + 1) * batch_size] for i in range(total_batches)]

# Dynamically create task groups for each batch
task_group_batches = []
for batch_index, datim_batch in enumerate(datim_batches):
    print(f'Batch {batch_index}: {datim_batch}')
    # task_group_batches.append(create_task_group_batch(datim_batch, batch_index))