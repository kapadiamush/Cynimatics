//
//  MoviesViewController.swift
//  Cynimatics
//
//  Created by Mushaheed Kapadia on 9/14/17.
//  Copyright © 2017 Mushaheed Kapadia. All rights reserved.
//

import UIKit
import MBProgressHUD

let nowPlayingState: String = "nowPlaying"
let topRatedState: String = "topRated"

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    
    @IBOutlet weak var moviesTableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!

    var searchActive: Bool = false
    var movies: [Movie] = []
    var filteredMovies: [Movie] = []
    var movieSet: String = nowPlayingState

    func fetchMoviesFunc(next: @escaping (([Movie]) ->Void)) {
        if self.movieSet == nowPlayingState {
            return fetchNowPlayingMovies(next: next)
        }
        else {
            return fetchTopRatedMovies(next: next)
        }
    }

    func fetchNowPlayingMovies(next: @escaping (([Movie]) -> Void)) {
        let url: String = "https://api.themoviedb.org/3/movie/now_playing"
        return fetchMovies(baseUrl: url, next: next)
    }
    
    func fetchTopRatedMovies(next: @escaping (([Movie]) -> Void)) {
        let url: String = "https://api.themoviedb.org/3/movie/top_rated"
        return fetchMovies(baseUrl: url, next: next)
    }

    
    func fetchMovies(baseUrl: String, next:  @escaping (([Movie]) -> Void)) {
        let apiKey: String = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url: URL = URL(string: "\(baseUrl)?api_key=\(apiKey)")!
        let request: URLRequest = URLRequest(url: url)
        let session: URLSession = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: nil,
            delegateQueue: OperationQueue.main
        )
        
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, err) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if err != nil {
                self.networkErrorView.isHidden = false
                self.networkErrorView.setNeedsDisplay()
                return next([])
            }
            
            if let data = data {
                self.networkErrorView.isHidden = true
                self.networkErrorView.setNeedsDisplay()
                if let responseDict = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    if let moviesList = responseDict["results"] as? [NSDictionary] {
                        let movies = moviesList.map({ (movieDict) -> Movie in
                            return Movie(from: movieDict)
                        })
                        return next(movies)
                    }
                }
                
            }
        }
        task.resume()
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(refreshControlAction(_:)),
            for: UIControlEvents.valueChanged
        )
        moviesTableView.insertSubview(refreshControl, at: 0)
        
        moviesTableView.dataSource = self
        moviesTableView.delegate = self
        searchBar.delegate = self
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        self.fetchMoviesFunc(next: { (movies) in
            self.movies = movies
            self.filteredMovies = movies
            self.moviesTableView.reloadData()
        })
        
        // Do any additional setup after loading the view.
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        self.fetchMoviesFunc { (movies) in
            self.movies = movies
            self.filteredMovies = movies
            self.moviesTableView.reloadData()
            refreshControl.endRefreshing()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return self.filteredMovies.count
        }
        else {
            return self.movies.count
        }
    }
    
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = moviesTableView.dequeueReusableCell(
            withIdentifier: "MovieCell",
            for: indexPath
        ) as! MovieTableViewCell

        cell.selectionStyle = .none
        var movie: Movie = self.movies[indexPath.row]
        if searchActive {
            movie = self.filteredMovies[indexPath.row]
        }
        cell.from(movie)
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filteredMovies = self.movies.filter({ (movie) -> Bool in
            let range = movie.title.range(of: searchText)
            return range != nil
        })
        searchActive = self.filteredMovies.count > 0
        self.moviesTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let movieCell = sender as! MovieTableViewCell
        let movieViewController = segue.destination as! MovieViewController
        movieViewController.movie = movieCell.movie
        
    }
    

}
