//
//  HomeViewController.swift
//  WatchaGot
//
//  Created by Julian Worden on 6/6/23.
//

import Combine
import SwiftPlus
import UIKit

class HomeViewController: UIViewController, MainViewController {
    lazy private var receiveButton = UIButton(configuration: .borderedProminentWithPaddedImage())
    lazy private var itemsTableView = UITableView()

    private var dataSource: UITableViewDiffableDataSource<HomeTableViewSection, Item>!

    var viewModel: HomeViewModel!
    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        createDiffableDataSource()
        configure()
        constrain()
        subscribeToPublishers()
        viewModel.fetchItems()
    }

    func configure() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Watcha Got?"

        receiveButton.setTitle("Receive New Item", for: .normal)
        receiveButton.setImage(UIImage(systemName: "tray.and.arrow.down"), for: .normal)
        receiveButton.addTarget(self, action: #selector(receiveButtonTapped), for: .touchUpInside)

        itemsTableView.delegate = self
        itemsTableView.dataSource = dataSource
        itemsTableView.register(HomeTableViewCell.self, forCellReuseIdentifier: Constants.homeTableViewCellReuseIdentifier)
    }

    func constrain() {
        view.addConstrainedSubviews(receiveButton, itemsTableView)

        NSLayoutConstraint.activate([
            receiveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            receiveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            receiveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            receiveButton.heightAnchor.constraint(equalToConstant: 40),

            itemsTableView.topAnchor.constraint(equalTo: receiveButton.bottomAnchor, constant: 10),
            itemsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            itemsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            itemsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func subscribeToPublishers() {
        viewModel.$items
            .sink { [weak self] items in

                let sortedItems = items.sorted { $0.name.lowercased() < $1.name.lowercased() }
                self?.updateDiffableDataSource(with: sortedItems)
            }
            .store(in: &cancellables)

        viewModel.$error
            .sink { [weak self] error in
                if let error {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
    }

    func showError(_ error: Error) {
        present(UIAlertController.genericError(error), animated: true)
    }

    @objc func receiveButtonTapped() {
        let addEditItemViewController = AddEditItemViewController()
        addEditItemViewController.viewModel = AddEditItemViewModel(itemToEdit: nil)
        addEditItemViewController.delegate = self
        let navigationController = UINavigationController(
            rootViewController: addEditItemViewController
        )
        present(navigationController, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate, AddEditItemDiffableDataSourceDelegate {
    private func createDiffableDataSource() {
        let dataSource = AddEditItemDiffableDataSource(tableView: itemsTableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.homeTableViewCellReuseIdentifier) else {
                return UITableViewCell()
            }

            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.text = item.name
            contentConfiguration.secondaryText = item.formattedPrice
            cell.contentConfiguration = contentConfiguration
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        dataSource.delegate = self
        self.dataSource = dataSource
    }

    private func updateDiffableDataSource(with items: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeTableViewSection, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selectedItem = viewModel.items[indexPath.row]
        let itemDetailsViewController = ItemDetailsViewController()
        itemDetailsViewController.viewModel = ItemDetailsViewModel(item: selectedItem)

        navigationController?.pushViewController(itemDetailsViewController, animated: true)
    }

    func addEditItemDiffableDataSource(didDeleteItemAt indexPath: IndexPath) {
        viewModel.deleteItem(at: indexPath)
    }
}

extension HomeViewController: AddEditItemViewControllerDelegate {
    func addEditItemViewController(didCreateItem item: Item) {
        viewModel.items.append(item)
    }

}

#Preview {
    let homeViewController = HomeViewController()
    let homeViewModel = HomeViewModel()
    homeViewController.viewModel = homeViewModel
    return UINavigationController(rootViewController: homeViewController)
}
