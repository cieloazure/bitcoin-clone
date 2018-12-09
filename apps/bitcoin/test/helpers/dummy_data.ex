defmodule DummyData do
  alias Bitcoin.Structures.{Block, Chain, Transaction}
  alias Bitcoin.Utilities.{BloomFilter, Crypto, MerkleTree}

  def get_chain() do
    # chain = Chain.new_chain(genesis_block)
    Chain.sort([block3(), block2(), block1(), genesis_block()], :height)
  end

  # def genesis_block do
  #   genesis_block(wallet1)
  # end

  # DUMMY BLOCKS #
  def genesis_block() do
    {:ok, timestamp} = DateTime.from_unix(1_543_220_522)

    %Bitcoin.Schemas.Block{
      block_header: %Bitcoin.Schemas.BlockHeader{
        bits: "1effffff",
        merkle_root:
          <<27, 231, 50, 246, 171, 36, 138, 218, 80, 122, 89, 75, 30, 127, 116, 173, 238, 62, 196,
            216, 252, 184, 220, 102, 40, 201, 141, 53, 190, 21, 42, 96>>,
        nonce: 1,
        prev_block_hash:
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0>>,
        timestamp: timestamp,
        version: 1
      },
      bloom_filter: [
        bits: [
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0
        ],
        length: 33,
        hash_fns: [:sha, :ripemd160, :sha256]
      ],
      height: 0,
      merkle_tree: %{
        0 => [
          <<122, 248, 29, 99, 84, 218, 217, 146, 113, 205, 87, 50, 73, 17, 184, 40, 32, 61, 32,
            75, 221, 199, 122, 208, 246, 150, 202, 136, 10, 26, 224, 226>>,
          <<122, 248, 29, 99, 84, 218, 217, 146, 113, 205, 87, 50, 73, 17, 184, 40, 32, 61, 32,
            75, 221, 199, 122, 208, 246, 150, 202, 136, 10, 26, 224, 226>>
        ],
        1 => [
          <<27, 231, 50, 246, 171, 36, 138, 218, 80, 122, 89, 75, 30, 127, 116, 173, 238, 62, 196,
            216, 252, 184, 220, 102, 40, 201, 141, 53, 190, 21, 42, 96>>
        ]
      },
      tx_counter: 1,
      txns: [
        %Bitcoin.Schemas.Transaction{
          input_counter: 1,
          inputs: [
            %Bitcoin.Schemas.Coinbase{
              coinbase: "0,2018-11-26 08:32:08.163619Z",
              sequence: 4_294_967_295
            }
          ],
          locktime: nil,
          output_counter: 1,
          outputs: [
            %Bitcoin.Schemas.TransactionOutput{
              address: nil,
              amount: 5_000_000_000,
              locking_script:
                "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
              output_index: 1,
              tx_id: "ed2cd331-fd93-4365-ba0b-14b6a1da8f07"
            }
          ],
          tx_id: "ed2cd331-fd93-4365-ba0b-14b6a1da8f07",
          version: nil
        }
      ]
    }
  end

  def get_block(last_block, transaction_pool, recipient, uuid) do
    prev_block_hash = Block.get_attr(last_block, :block_header) |> Crypto.double_sha256()
    height = Block.get_attr(last_block, :height) + 1

    {:ok, timestamp} =
      Map.get(last_block, :block_header)
      |> Map.get(:timestamp)
      |> DateTime.to_unix()
      |> (fn d -> d + 60 * 60 end).()
      |> DateTime.from_unix()

    gen_tx = %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.Coinbase{
          coinbase: "#{height},#{timestamp}",
          sequence: 4_294_967_295
        }
      ],
      locktime: nil,
      output_counter: 1,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount:
            Bitcoin.Structures.Block.get_block_value(height, length(transaction_pool) * 1000),
          locking_script: "DUP / HASH160 / BASE58CHECK / #{recipient} / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: uuid
        }
      ],
      tx_id: uuid,
      version: nil
    }

    # {:ok, gen_tx} =
    #   Bitcoin.Structures.Transaction.create_generation_transaction(
    #     height,
    #     length(transaction_pool) * 1000,
    #     recipient
    #   )

    transaction_pool = [gen_tx | transaction_pool]

    {merkle_root, merkle_tree} = MerkleTree.calculate_hash(transaction_pool)

    tx_ids = Enum.map(transaction_pool, fn tx -> Map.get(tx, :tx_id) end)
    bloom_filter = BloomFilter.init(10, 0.2) |> BloomFilter.put(tx_ids)

    header = %Bitcoin.Schemas.BlockHeader{
      version: 1,
      timestamp: timestamp,
      prev_block_hash: prev_block_hash,
      nonce: 1,
      bits: 2,
      merkle_root: merkle_root
    }

    %Bitcoin.Schemas.Block{
      block_header: header,
      txns: transaction_pool,
      tx_counter: length(transaction_pool),
      height: height,
      merkle_tree: merkle_tree,
      bloom_filter: bloom_filter
    }
  end

  def block1() do
    get_block(
      genesis_block(),
      [tx1()],
      wallet2() |> Keyword.get(:address),
      "d8e4f4e8-f2e5-4683-ab81-9322d5cc100f"
    )

    # IO.puts("block1 inspect(block1)")
    # block1
  end

  def block2() do
    get_block(
      block1(),
      [tx2(), tx3()],
      wallet1() |> Keyword.get(:address),
      "be5fa0b4-8bbd-4ee0-8b6c-4f9491eafcba"
    )

    # IO.puts("block2 inspect(block2)")
    # block2
  end

  def block3() do
    get_block(
      block2(),
      [tx4()],
      wallet3() |> Keyword.get(:address),
      "2ed6030f-5afc-4bf4-99db-704be173443f"
    )

    # IO.puts("block3 inspect(block3)")
    # block3
  end

  # def get_wallets(count \\ 1) do
  #   for i <- 0..count do
  #     Bitcoin.Wallet.init_wallet()
  #   end
  # end

  # def generate_txns do
  #   [tx1, tx2, tx3, tx4]
  # end

  # DUMMY WALLETS #
  def wallet1() do
    [
      private_key:
        <<109, 156, 136, 220, 11, 6, 161, 198, 141, 101, 223, 121, 83, 121, 15, 123, 97, 31, 127,
          117, 86, 220, 128, 48, 132, 71, 246, 129, 153, 109, 70, 37>>,
      public_key:
        <<4, 107, 154, 45, 160, 184, 29, 45, 220, 226, 32, 71, 30, 106, 206, 19, 199, 219, 147,
          118, 202, 23, 72, 133, 148, 240, 229, 86, 222, 127, 53, 246, 167, 52, 196, 139, 203,
          158, 216, 204, 25, 63, 255, 191, 230, 193, 55, 192, 202, 128, 226, 247, 85, 172, 8, 6,
          101, 103, 232, 39, 137, 235, 48, 38, 146>>,
      address: "1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5"
    ]
  end

  def wallet2() do
    [
      private_key:
        <<85, 0, 128, 45, 105, 227, 88, 30, 225, 207, 125, 97, 147, 169, 10, 41, 161, 145, 140,
          245, 246, 240, 85, 172, 13, 61, 87, 201, 81, 149, 8, 140>>,
      public_key:
        <<4, 18, 104, 17, 28, 178, 161, 242, 157, 156, 22, 212, 132, 117, 2, 206, 66, 17, 67, 72,
          201, 112, 251, 123, 47, 165, 234, 148, 211, 159, 69, 214, 242, 157, 40, 81, 235, 119,
          61, 195, 39, 201, 238, 112, 233, 175, 251, 203, 147, 243, 247, 125, 188, 18, 149, 177,
          119, 5, 30, 85, 144, 14, 226, 121, 106>>,
      address: "1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6"
    ]
  end

  def wallet3() do
    [
      private_key:
        <<75, 87, 171, 24, 209, 105, 22, 88, 205, 164, 187, 212, 175, 15, 153, 194, 77, 211, 157,
          58, 156, 215, 237, 6, 70, 90, 144, 198, 243, 191, 63, 102>>,
      public_key:
        <<4, 54, 242, 148, 139, 242, 61, 52, 49, 170, 105, 107, 124, 13, 23, 73, 174, 51, 7, 48,
          38, 200, 50, 237, 195, 63, 56, 122, 77, 226, 176, 171, 38, 66, 208, 40, 19, 159, 75,
          213, 197, 10, 227, 232, 98, 73, 203, 19, 244, 251, 88, 185, 209, 130, 182, 249, 36, 28,
          85, 165, 103, 201, 141, 139, 110>>,
      address: "1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA"
    ]
  end

  # DUMMY TRANSACTIONS #

  def set_uuid(tx, uuid) do
    tx = Map.put(tx, :tx_id, uuid)

    tx_outputs =
      Map.get(tx, :outputs)
      |> Enum.map(fn output ->
        Map.put(output, :tx_id, uuid)
      end)

    Map.put(tx, :outputs, tx_outputs)
  end

  # VALID Transactions #

  # first transaction from wallet1 to wallet2
  # def tx1() do
  #   utxo = genesis_block() |> Map.get(:txns) |> Enum.at(0) |> Map.get(:outputs)
  #   recipient = wallet2() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet1(), recipient, utxo, 500_000_000, 1000)
  #   set_uuid(tx, "300e4248-739b-47f1-899a-6d4b3b235efc")
  # end
  def tx1() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "ed2cd331-fd93-4365-ba0b-14b6a1da8f07",
          unlocking_script:
            <<48, 70, 2, 33, 0, 228, 138, 200, 122, 78, 94, 130, 103, 32, 89, 234, 64, 6, 121,
              235, 17, 40, 249, 189, 116, 87, 141, 194, 3, 180, 42, 111, 232, 229, 246, 147, 111,
              2, 33, 0, 180, 133, 125, 184, 201, 9, 52, 188, 36, 255, 252, 202, 66, 30, 190, 174,
              168, 11, 219, 158, 183, 109, 61, 65, 80, 66, 201, 42, 208, 205, 223, 111, 32, 47,
              32, 4, 107, 154, 45, 160, 184, 29, 45, 220, 226, 32, 71, 30, 106, 206, 19, 199, 219,
              147, 118, 202, 23, 72, 133, 148, 240, 229, 86, 222, 127, 53, 246, 167, 52, 196, 139,
              203, 158, 216, 204, 25, 63, 255, 191, 230, 193, 55, 192, 202, 128, 226, 247, 85,
              172, 8, 6, 101, 103, 232, 39, 137, 235, 48, 38, 146>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 500_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 4_499_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc"
        }
      ],
      tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc",
      version: nil
    }
  end

  # Second transaction. from wallet2 to wallet3
  # def tx2() do
  #   utxo =
  #     tx1()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   recipient = wallet3() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet2(), recipient, [utxo], 100_000_000, 1000)
  #   tx
  # end
  def tx2() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc",
          unlocking_script:
            <<48, 70, 2, 33, 0, 200, 49, 17, 251, 98, 139, 0, 61, 116, 110, 79, 165, 230, 29, 21,
              242, 84, 88, 180, 150, 41, 54, 163, 232, 211, 137, 18, 58, 204, 141, 121, 57, 2, 33,
              0, 190, 202, 216, 149, 83, 41, 114, 61, 243, 146, 122, 197, 82, 125, 235, 6, 74,
              113, 165, 172, 187, 44, 94, 39, 39, 27, 112, 142, 123, 51, 82, 39, 32, 47, 32, 4,
              18, 104, 17, 28, 178, 161, 242, 157, 156, 22, 212, 132, 117, 2, 206, 66, 17, 67, 72,
              201, 112, 251, 123, 47, 165, 234, 148, 211, 159, 69, 214, 242, 157, 40, 81, 235,
              119, 61, 195, 39, 201, 238, 112, 233, 175, 251, 203, 147, 243, 247, 125, 188, 18,
              149, 177, 119, 5, 30, 85, 144, 14, 226, 121, 106>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 100_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "a14cdf33-c921-48ec-b9cb-0c7ca0836f73"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 399_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "a14cdf33-c921-48ec-b9cb-0c7ca0836f73"
        }
      ],
      tx_id: "a14cdf33-c921-48ec-b9cb-0c7ca0836f73",
      version: nil
    }
  end

  # Third transaction. form wallet1 to wallet3
  # def tx3() do
  #   utxo =
  #     tx1()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 2 end)

  #   recipient = wallet3() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet1(), recipient, [utxo], 700_000_000, 1000)
  #   tx
  # end
  def tx3() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 2,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc",
          unlocking_script:
            <<48, 70, 2, 33, 0, 247, 159, 176, 23, 28, 82, 6, 112, 253, 124, 187, 167, 246, 31,
              32, 102, 27, 125, 158, 68, 39, 24, 234, 216, 129, 179, 79, 235, 26, 175, 50, 127, 2,
              33, 0, 219, 156, 20, 244, 24, 141, 49, 238, 221, 249, 196, 131, 169, 239, 91, 199,
              229, 207, 11, 73, 152, 74, 60, 147, 244, 144, 231, 35, 29, 46, 101, 110, 32, 47, 32,
              4, 107, 154, 45, 160, 184, 29, 45, 220, 226, 32, 71, 30, 106, 206, 19, 199, 219,
              147, 118, 202, 23, 72, 133, 148, 240, 229, 86, 222, 127, 53, 246, 167, 52, 196, 139,
              203, 158, 216, 204, 25, 63, 255, 191, 230, 193, 55, 192, 202, 128, 226, 247, 85,
              172, 8, 6, 101, 103, 232, 39, 137, 235, 48, 38, 146>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 700_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "d63a4772-46f6-4362-829b-01ab5baf4603"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 3_799_998_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "d63a4772-46f6-4362-829b-01ab5baf4603"
        }
      ],
      tx_id: "d63a4772-46f6-4362-829b-01ab5baf4603",
      version: nil
    }
  end

  # Fourth transaction. from wallet3 to wallet2
  # def tx4() do
  #   utxo1 =
  #     tx3()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   utxo2 =
  #     tx2()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   recipient = wallet2() |> Keyword.get(:address)

  #   {:ok, tx} =
  #     Transaction.create_transaction(wallet3(), recipient, [utxo1, utxo2], 750_000_000, 1000)

  #   tx
  # end
  def tx4() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 2,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "d63a4772-46f6-4362-829b-01ab5baf4603",
          unlocking_script:
            <<48, 69, 2, 32, 117, 111, 207, 33, 101, 34, 88, 153, 14, 159, 47, 22, 94, 110, 34,
              227, 1, 1, 111, 3, 38, 7, 82, 72, 103, 225, 229, 95, 198, 119, 68, 78, 2, 33, 0,
              214, 49, 21, 236, 183, 247, 100, 173, 68, 133, 231, 64, 49, 234, 244, 236, 180, 210,
              46, 222, 191, 216, 105, 183, 68, 195, 30, 177, 134, 245, 103, 154, 32, 47, 32, 4,
              54, 242, 148, 139, 242, 61, 52, 49, 170, 105, 107, 124, 13, 23, 73, 174, 51, 7, 48,
              38, 200, 50, 237, 195, 63, 56, 122, 77, 226, 176, 171, 38, 66, 208, 40, 19, 159, 75,
              213, 197, 10, 227, 232, 98, 73, 203, 19, 244, 251, 88, 185, 209, 130, 182, 249, 36,
              28, 85, 165, 103, 201, 141, 139, 110>>,
          unlocking_script_size: nil
        },
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "a14cdf33-c921-48ec-b9cb-0c7ca0836f73",
          unlocking_script:
            <<48, 70, 2, 33, 0, 232, 50, 38, 66, 215, 61, 159, 65, 110, 51, 129, 63, 75, 195, 182,
              183, 92, 150, 17, 223, 167, 162, 229, 19, 233, 127, 120, 195, 29, 176, 242, 55, 2,
              33, 0, 150, 190, 232, 56, 152, 206, 14, 34, 25, 130, 157, 214, 220, 18, 134, 95,
              139, 55, 43, 125, 207, 158, 101, 41, 160, 54, 15, 93, 134, 197, 157, 148, 32, 47,
              32, 4, 54, 242, 148, 139, 242, 61, 52, 49, 170, 105, 107, 124, 13, 23, 73, 174, 51,
              7, 48, 38, 200, 50, 237, 195, 63, 56, 122, 77, 226, 176, 171, 38, 66, 208, 40, 19,
              159, 75, 213, 197, 10, 227, 232, 98, 73, 203, 19, 244, 251, 88, 185, 209, 130, 182,
              249, 36, 28, 85, 165, 103, 201, 141, 139, 110>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 750_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "b030bcfc-9ef9-4246-96a8-bd569c402d6d"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 49_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "b030bcfc-9ef9-4246-96a8-bd569c402d6d"
        }
      ],
      tx_id: "b030bcfc-9ef9-4246-96a8-bd569c402d6d",
      version: nil
    }
  end

  # Fifth transaction. wallet1 to wallet3
  # def tx5() do
  #   utxo =
  #     tx3()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 2 end)

  #   recipient = wallet3() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet1(), recipient, [utxo], 2000_000_000, 1000)
  #   tx
  # end
  def tx5() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 2,
          tx_id: "d63a4772-46f6-4362-829b-01ab5baf4603",
          unlocking_script:
            <<48, 68, 2, 32, 45, 156, 128, 218, 141, 45, 81, 161, 217, 190, 255, 179, 159, 98,
              233, 246, 235, 240, 104, 144, 174, 242, 67, 25, 190, 18, 59, 129, 218, 27, 224, 43,
              2, 32, 52, 25, 71, 177, 116, 251, 72, 9, 152, 18, 37, 243, 62, 75, 61, 9, 114, 173,
              147, 121, 156, 178, 182, 220, 126, 171, 129, 138, 143, 206, 81, 162, 32, 47, 32, 4,
              107, 154, 45, 160, 184, 29, 45, 220, 226, 32, 71, 30, 106, 206, 19, 199, 219, 147,
              118, 202, 23, 72, 133, 148, 240, 229, 86, 222, 127, 53, 246, 167, 52, 196, 139, 203,
              158, 216, 204, 25, 63, 255, 191, 230, 193, 55, 192, 202, 128, 226, 247, 85, 172, 8,
              6, 101, 103, 232, 39, 137, 235, 48, 38, 146>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 2_000_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "fc471076-f7be-493b-8ee5-30cefd47a2f3"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 1_799_997_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "fc471076-f7be-493b-8ee5-30cefd47a2f3"
        }
      ],
      tx_id: "fc471076-f7be-493b-8ee5-30cefd47a2f3",
      version: nil
    }
  end

  # INVALID TRANSACTIONS #
  # reuses transaction output used in tx2.
  # wallet2 to wallet 1 using tx_output used in tx2().
  # def inv_tx1() do
  #   utxo =
  #     tx1()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   recipient = wallet1() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet2(), recipient, [utxo], 2_000_000, 1000)
  #   tx
  # end
  def inv_tx1() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc",
          unlocking_script:
            <<48, 69, 2, 33, 0, 145, 101, 240, 212, 131, 155, 206, 118, 242, 23, 223, 67, 23, 180,
              65, 243, 245, 177, 3, 123, 11, 26, 224, 73, 116, 75, 56, 68, 4, 3, 1, 177, 2, 32,
              126, 162, 235, 233, 226, 189, 126, 87, 74, 118, 33, 85, 103, 5, 242, 242, 64, 177,
              86, 66, 219, 105, 198, 82, 165, 162, 74, 243, 15, 6, 243, 202, 32, 47, 32, 4, 18,
              104, 17, 28, 178, 161, 242, 157, 156, 22, 212, 132, 117, 2, 206, 66, 17, 67, 72,
              201, 112, 251, 123, 47, 165, 234, 148, 211, 159, 69, 214, 242, 157, 40, 81, 235,
              119, 61, 195, 39, 201, 238, 112, 233, 175, 251, 203, 147, 243, 247, 125, 188, 18,
              149, 177, 119, 5, 30, 85, 144, 14, 226, 121, 106>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 2_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 497_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1"
        }
      ],
      tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1",
      version: nil
    }
  end

  # incorrect unlocking script / not the authorized receiver of transaction_output.
  # wallet3 trying to make transaction using utxo authorized for walltet2.
  # def inv_tx2() do
  #   utxo =
  #     tx4()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   recipient = wallet1() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet3(), recipient, [utxo], 2_000_000, 1000)
  #   tx
  # end
  def inv_tx2() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "300e4248-739b-47f1-899a-6d4b3b235efc",
          unlocking_script:
            <<48, 69, 2, 33, 0, 145, 101, 240, 212, 131, 155, 206, 118, 242, 23, 223, 67, 23, 180,
              65, 243, 245, 177, 3, 123, 11, 26, 224, 73, 116, 75, 56, 68, 4, 3, 1, 177, 2, 32,
              126, 162, 235, 233, 226, 189, 126, 87, 74, 118, 33, 85, 103, 5, 242, 242, 64, 177,
              86, 66, 219, 105, 198, 82, 165, 162, 74, 243, 15, 6, 243, 202, 32, 47, 32, 4, 18,
              104, 17, 28, 178, 161, 242, 157, 156, 22, 212, 132, 117, 2, 206, 66, 17, 67, 72,
              201, 112, 251, 123, 47, 165, 234, 148, 211, 159, 69, 214, 242, 157, 40, 81, 235,
              119, 61, 195, 39, 201, 238, 112, 233, 175, 251, 203, 147, 243, 247, 125, 188, 18,
              149, 177, 119, 5, 30, 85, 144, 14, 226, 121, 106>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 2_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1LnTWuHkrsX5ZqTs36FjyAdmhdJdqaHyh5 / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 497_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1"
        }
      ],
      tx_id: "f55ba380-3f7b-4e99-97ee-0e25441c9fc1",
      version: nil
    }
  end

  # ORPHAN TRANSACTIONS #
  # uses output from tx5(), which is not included in the blockchain as input.
  # wallet2 trying to make transaction using utxo authorized for walltet3.
  # def orphan_tx1() do
  #   utxo =
  #     tx5()
  #     |> Map.get(:outputs)
  #     |> Enum.find(fn output -> Map.get(output, :output_index) == 1 end)

  #   recipient = wallet2() |> Keyword.get(:address)

  #   {:ok, tx} = Transaction.create_transaction(wallet3(), recipient, [utxo], 10_000_000, 1000)
  #   tx
  # end
  def orphan_tx1() do
    %Bitcoin.Schemas.Transaction{
      input_counter: 1,
      inputs: [
        %Bitcoin.Schemas.TransactionInput{
          output_index: 1,
          tx_id: "fc471076-f7be-493b-8ee5-30cefd47a2f3",
          unlocking_script:
            <<48, 69, 2, 32, 54, 159, 170, 98, 198, 113, 118, 29, 156, 125, 83, 178, 107, 59, 131,
              250, 185, 231, 190, 201, 147, 64, 254, 42, 149, 107, 47, 195, 24, 159, 153, 185, 2,
              33, 0, 228, 155, 31, 33, 78, 221, 128, 147, 61, 183, 79, 147, 183, 148, 229, 96, 94,
              248, 49, 73, 41, 1, 73, 195, 129, 76, 37, 176, 117, 91, 70, 191, 32, 47, 32, 4, 54,
              242, 148, 139, 242, 61, 52, 49, 170, 105, 107, 124, 13, 23, 73, 174, 51, 7, 48, 38,
              200, 50, 237, 195, 63, 56, 122, 77, 226, 176, 171, 38, 66, 208, 40, 19, 159, 75,
              213, 197, 10, 227, 232, 98, 73, 203, 19, 244, 251, 88, 185, 209, 130, 182, 249, 36,
              28, 85, 165, 103, 201, 141, 139, 110>>,
          unlocking_script_size: nil
        }
      ],
      locktime: nil,
      output_counter: 2,
      outputs: [
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 10_000_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1UcBoCZQB8FCwbFGPqsMwUFuJhRChg8iK6 / EQUALVERIFY / CHECKSIG",
          output_index: 1,
          tx_id: "3e567d90-5610-42a8-9590-d07e64c257d6"
        },
        %Bitcoin.Schemas.TransactionOutput{
          address: nil,
          amount: 1_989_999_000,
          locking_script:
            "DUP / HASH160 / BASE58CHECK / 1X5phXKrhLPWwhiFZSer5DHM7xJNFumKKA / EQUALVERIFY / CHECKSIG",
          output_index: 2,
          tx_id: "3e567d90-5610-42a8-9590-d07e64c257d6"
        }
      ],
      tx_id: "3e567d90-5610-42a8-9590-d07e64c257d6",
      version: nil
    }
  end
end
